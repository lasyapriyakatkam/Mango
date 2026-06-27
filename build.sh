#!/bin/bash
# Builds Mango.app from the Swift sources using the command-line toolchain.
set -e
cd "$(dirname "$0")"

APP="Mango.app"
MACOS_DIR="$APP/Contents/MacOS"
BIN="$MACOS_DIR/Mango"

echo "Compiling…"
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$APP/Contents/Resources"

swiftc -O \
    -framework AppKit \
    Sources/Mango/*.swift \
    -o "$BIN"

cp Info.plist "$APP/Contents/Info.plist"
if [ -f Tools/AppIcon.icns ]; then
    cp Tools/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

echo "Built ./$APP"
echo "Run it with:  open ./$APP"
echo "Quit it from the 🐾 menu-bar icon."
