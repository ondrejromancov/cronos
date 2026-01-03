#!/bin/bash
set -euo pipefail

APP_NAME="Cronos"
VERSION="${1:-1.0.0}"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "Building $APP_NAME version $VERSION..."

# Build the app
xcodebuild \
    -project Cronos.xcodeproj \
    -scheme Cronos \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -destination 'generic/platform=macOS' \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_HARDENED_RUNTIME=NO \
    clean build

# Find the built app
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)

if [[ -z "$APP_PATH" ]]; then
    echo "Error: Could not find built app"
    exit 1
fi

echo "Found app at: $APP_PATH"

# Remove extended attributes
xattr -cr "$APP_PATH"

# Create staging directory
rm -rf dmg-staging
mkdir -p dmg-staging
cp -R "$APP_PATH" dmg-staging/
ln -s /Applications dmg-staging/Applications

# Create DMG
rm -f "$DMG_NAME"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder dmg-staging \
    -ov \
    -format UDZO \
    "$DMG_NAME"

# Cleanup
rm -rf dmg-staging

# Calculate checksum
echo ""
echo "Created: $DMG_NAME"
echo "SHA256: $(shasum -a 256 "$DMG_NAME" | awk '{print $1}')"
