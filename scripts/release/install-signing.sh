#!/usr/bin/env bash
set -euo pipefail
umask 077

dir="$RUNNER_TEMP/ios-signing"
keychain="$dir/build.keychain-db"
if [[ "${1:-}" == cleanup ]]; then
  if [[ -f "$dir/profile-path" ]]; then
    rm -f -- "$(cat "$dir/profile-path")"
  fi
  security delete-keychain "$keychain" 2>/dev/null || true
  rm -rf -- "$dir"
  exit 0
fi

: "${CERTIFICATE:?Missing distribution certificate}" "${CERTIFICATE_PASSWORD:?Missing certificate password}" "${PROFILE:?Missing app provisioning profile}"
mkdir -p "$dir"
printf '%s' "$CERTIFICATE" | base64 -D > "$dir/distribution.p12"
printf '%s' "$PROFILE" | base64 -D > "$dir/profile.mobileprovision"
unset CERTIFICATE PROFILE
security cms -D -i "$dir/profile.mobileprovision" > "$dir/profile.plist"
plist=/usr/libexec/PlistBuddy
team=$("$plist" -c 'Print :TeamIdentifier:0' "$dir/profile.plist")
uuid=$("$plist" -c 'Print :UUID' "$dir/profile.plist")
application=$("$plist" -c 'Print :Entitlements:application-identifier' "$dir/profile.plist")
[[ "$team" =~ ^[A-Z0-9]{10}$ && "$uuid" =~ ^[a-fA-F0-9-]{36}$ && "$application" == "$team.$BUNDLE_ID" ]]
python3 - "$dir/profile.plist" <<'PY'
import datetime
import plistlib
import sys

with open(sys.argv[1], "rb") as file:
    profile = plistlib.load(file)
if profile["ExpirationDate"].replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
    sys.exit("Provisioning profile has expired.")
if (profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices")
        or profile["Entitlements"].get("get-task-allow")):
    sys.exit("Use an App Store Connect distribution profile.")
PY

password=$(openssl rand -hex 32)
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$dir/distribution.p12" -k "$keychain" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
unset CERTIFICATE_PASSWORD
rm -f "$dir/distribution.p12"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain"
security list-keychains -d user -s "$keychain"
security find-identity -v -p codesigning "$keychain" | grep -F 'Apple Distribution:'

profiles="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profiles"
printf '%s\n' "$profiles/$uuid.mobileprovision" > "$dir/profile-path"
cp "$dir/profile.mobileprovision" "$profiles/$uuid.mobileprovision"

GEM_HOME="$RUNNER_TEMP/signing-gems" gem install xcodeproj --version 1.27.0 --no-document
GEM_HOME="$RUNNER_TEMP/signing-gems" ruby -r xcodeproj - "$team" "$uuid" <<'RUBY'
team, uuid = ARGV
project = Xcodeproj::Project.open("ios/Runner.xcodeproj")
runner = project.targets.find { |target| target.name == "Runner" }
release = runner.build_configurations.find { |configuration| configuration.name == "Release" }
release.build_settings.merge!(
  "CODE_SIGN_STYLE" => "Manual",
  "CODE_SIGN_IDENTITY[sdk=iphoneos*]" => "Apple Distribution",
  "DEVELOPMENT_TEAM" => team,
  "PROVISIONING_PROFILE_SPECIFIER" => "",
  "PROVISIONING_PROFILE" => uuid
)
project.save
RUBY

python3 - "$dir/export.plist" "$team" "$uuid" <<'PY'
import os
import plistlib
import sys

path, team, uuid = sys.argv[1:]
with open(path, "wb") as file:
    plistlib.dump({
        "destination": "export",
        "method": "app-store-connect",
        "manageAppVersionAndBuildNumber": False,
        "provisioningProfiles": {os.environ["BUNDLE_ID"]: uuid},
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "teamID": team,
    }, file)
PY
