import os
import plistlib
import re
import sys

with open(sys.argv[1], "rb") as file:
    info = plistlib.load(file)

for key, name in {
    "CFBundleIdentifier": "BUNDLE_ID",
    "CFBundleShortVersionString": "VERSION",
    "CFBundleVersion": "BUILD_NUMBER",
}.items():
    expected = os.environ[name]
    if info.get(key) != expected:
        sys.exit(f"{key}: expected {expected!r}, got {info.get(key)!r}")
    print(f"{key} = {expected}")

sdk = info.get("DTSDKName", "")
match = re.fullmatch(r"iphoneos(\d+)(?:\.\d+)*", sdk) if isinstance(sdk, str) else None
if not match or int(match.group(1)) < 27:
    sys.exit(f"DTSDKName: expected iOS SDK 27 or newer, got {sdk!r}")
print(f"DTSDKName = {sdk}")
