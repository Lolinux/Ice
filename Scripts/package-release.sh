#!/bin/bash
# Produce a reproducible local Apple Silicon release; signing keys stay outside Git.
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="${ICE_RELEASE_DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData/Ice-MacOS27-Release}"
OUTPUT="${ICE_PACKAGE_OUTPUT:-$PROJECT_ROOT/build/release}"
VERSION="0.12.0-macos27.local2"
BUILD_NUMBER=1329
mkdir -p "$OUTPUT"

xcodebuild -project "$PROJECT_ROOT/Ice.xcodeproj" -scheme Ice \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ARCHS=arm64 \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO ENABLE_HARDENED_RUNTIME=NO \
  ENABLE_DEBUG_DYLIB=NO ENABLE_PREVIEWS=NO \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) ICE_LOCAL_BUILD' \
  ICE_APP_BUNDLE_IDENTIFIER=com.jordanbaird.Ice.macos27debug \
  INFOPLIST_KEY_CFBundleDisplayName='Ice 27' \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" build

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/ice-release.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/Ice 27.app"
ditto "$DERIVED_DATA/Build/Products/Release/Ice.app" "$APP"
# A local fork must not advertise the upstream project's release feed.
/usr/libexec/PlistBuddy -c 'Delete :SUFeedURL' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Delete :SUPublicEDKey' "$APP/Contents/Info.plist"
python3 "$PROJECT_ROOT/Scripts/sign-local.py" "$APP"
python3 - "$APP" <<'PY'
import pathlib, plistlib, subprocess, sys
app = pathlib.Path(sys.argv[1])
result = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(app)], capture_output=True, check=True)
entitlements = plistlib.loads(result.stdout) if result.stdout.strip() else {}
assert not entitlements.get('com.apple.security.get-task-allow'), 'Release must not allow debugger attachment'
assert not (app / 'Contents/MacOS/Ice.debug.dylib').exists(), 'Release contains a debug dylib'
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert 'SUFeedURL' not in info, 'Local release must not use the upstream updater'
print('Release checks passed: no debug attachment entitlement, debug dylib, or upstream feed.')
PY
cp "$PROJECT_ROOT/Scripts/RELEASE-NOTES.zh-CN.md" "$STAGING/使用说明.md"
cp "$PROJECT_ROOT/LICENSE" "$STAGING/LICENSE"
PACKAGE="Ice-27-$VERSION-arm64"
hdiutil create -volname 'Ice 27' -srcfolder "$STAGING" -format UDZO -ov "$OUTPUT/$PACKAGE.dmg"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUTPUT/$PACKAGE.zip"
(cd "$OUTPUT" && shasum -a 256 "$PACKAGE.dmg" "$PACKAGE.zip" > SHA256SUMS.txt)
printf 'Release package: %s/%s.dmg\n' "$OUTPUT" "$PACKAGE"
