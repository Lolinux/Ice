#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="${ICE_DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData/Ice-MacOS27}"

# Override the application identity only. The embedded XPC service must retain
# its own identifier, which is also used when opening the service connection.
xcodebuild -project "$PROJECT_ROOT/Ice.xcodeproj" -scheme Ice \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  ENABLE_HARDENED_RUNTIME=NO \
  ENABLE_DEBUG_DYLIB=NO \
  ICE_APP_BUNDLE_IDENTIFIER=com.jordanbaird.Ice.macos27debug \
  INFOPLIST_KEY_CFBundleDisplayName='Ice 27 Debug' build

# A stable certificate requirement lets macOS recognize subsequent local builds.
python3 "$PROJECT_ROOT/Scripts/sign-local.py" "$DERIVED_DATA/Build/Products/Debug/Ice.app"

echo "Debug app: $DERIVED_DATA/Build/Products/Debug/Ice.app"
