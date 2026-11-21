#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${ASC_KEY:?Missing App Store Connect private key}"
[[ "$ASC_KEY_ID" =~ ^[A-Z0-9]+$ && "$ASC_ISSUER_ID" =~ ^[a-fA-F0-9-]{36}$ ]]
shopt -s nullglob
ipas=(build/ios/ipa/*.ipa)
[[ "${#ipas[@]}" == 1 ]] || { echo "Expected exactly one IPA."; exit 1; }

info="$RUNNER_TEMP/exported-info.plist"
unzip -p "${ipas[0]}" 'Payload/*.app/Info.plist' > "$info"
python3 scripts/release/check-app.py "$info"

key_dir="$HOME/.appstoreconnect/private_keys"
mkdir -p "$key_dir"
key="$key_dir/AuthKey_$ASC_KEY_ID.p8"
trap 'rm -f -- "$key"' EXIT
printf '%s\n' "$ASC_KEY" > "$key"
unset ASC_KEY
xcrun altool --validate-app --type ios --file "${ipas[0]}" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
xcrun altool --upload-app --type ios --file "${ipas[0]}" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
