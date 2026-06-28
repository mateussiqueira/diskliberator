#!/bin/bash
set -e
echo "=== DiskLiberator Build ==="
echo "1. Generating Xcode project..."
rm -rf DiskLiberator.xcodeproj
xcodegen generate --project .

echo "2. Building Release..."
xcodebuild -project DiskLiberator.xcodeproj -scheme DiskLiberator -configuration Release -derivedDataPath /tmp/DL-Release build

APP="/tmp/DL-Release/Build/Products/Release/DiskLiberator.app"
if [ -d "$APP" ]; then
    echo "3. Creating DMG..."
    DMG="/tmp/DiskLiberator-1.0.0.dmg"
    rm -f "$DMG"
    hdiutil create -volname "DiskLiberator" -srcfolder "$APP" -ov -format UDZO "$DMG" 2>/dev/null
    echo ""
    echo "=== BUILD COMPLETE ==="
    echo "App: $APP"
    echo "DMG: $DMG"
    echo ""
    echo "To run: open \"$APP\""
    echo "To distribute: open \"$DMG\""
else
    echo "BUILD FAILED - app not found"
    exit 1
fi
