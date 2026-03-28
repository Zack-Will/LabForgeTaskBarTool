#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/LabForgeMenuBar.app"
DMG_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DMG_DIR/dmg-staging"
DMG_PATH="$DMG_DIR/LabForgeMenuBar.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found at: $APP_PATH"
  echo "Run ./scripts/package_app.sh first."
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "LabForgeMenuBar" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$STAGING_DIR"

echo "Packaged DMG:"
echo "$DMG_PATH"
