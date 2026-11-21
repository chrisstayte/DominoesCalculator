import os
import plistlib
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
