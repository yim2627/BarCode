#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/BarCode.xcodeproj"
SCHEME="BarCode"
APP_NAME="BarCode"
CONFIG="Release"
BUILD_DIR="$ROOT/build"
DMG_DIR="$ROOT/dist"
DMG_NAME="${APP_NAME}.dmg"
STAGING="$BUILD_DIR/dmg-staging"
VERSION="${1:-}"

echo "==> Cleaning"
rm -rf "$BUILD_DIR" "$DMG_DIR/$DMG_NAME" "$STAGING"
mkdir -p "$BUILD_DIR" "$DMG_DIR"

if [ -n "$VERSION" ]; then
  echo "==> Stamping Info.plist with version $VERSION"
  plutil -replace CFBundleShortVersionString -string "$VERSION" "$ROOT/BarCode/Info.plist"
fi

echo "==> Building $CONFIG"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination 'platform=macOS' \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  build > "$BUILD_DIR/build.log" 2>&1 || {
    echo "❌ Build failed. Tail of log:"
    tail -40 "$BUILD_DIR/build.log"
    exit 1
  }

APP_PATH=$(find "$BUILD_DIR/DerivedData/Build/Products/$CONFIG" -name "$APP_NAME.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
  echo "❌ Built .app not found"
  exit 1
fi

echo "==> Staging at $STAGING"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> Creating DMG"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG_DIR/$DMG_NAME" > /dev/null

SIZE=$(du -h "$DMG_DIR/$DMG_NAME" | cut -f1)
echo ""
echo "✅ Done: $DMG_DIR/$DMG_NAME ($SIZE)"
