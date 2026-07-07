#!/bin/bash
set -euo pipefail

# Configuration
# This script assumes it is run from the root of the FUZZEL source tree.
FUZZEL_DIR="."
PATCH_DIR="patches"
NEW_FILES="new_files"
BUILD_DIR="fuzzel_custom_build"

echo "🚀 Starting Custom Fuzzel Build Process..."

if [ ! -d "$FUZZEL_DIR/src" ]; then
    echo "Error: Could not find fuzzel source in $FUZZEL_DIR. Please run this script from the fuzzel source root."
    exit 1
fi

# 1. Clone/Setup Build Directory
if [ -d "$BUILD_DIR" ]; then rm -rf "$BUILD_DIR"; fi
cp -r "$FUZZEL_DIR" "$BUILD_DIR"
cd "$BUILD_DIR"

# 2. Apply Patches
echo "🎨 Applying aesthetic and semantic patches..."
for patch in "$OLDPWD/$PATCH_DIR"/*.patch; do
    echo "Applying $patch..."
    # Using -p1 as standard for git-style patches
    patch -p1 < "$patch" || { echo "Warning: Patch $patch failed to apply cleanly. Check context."; }
done

# 3. Inject OCWS Bridge
echo "🔌 Injecting OCWS Bridge source..."
if [ -d "$OLDPWD/$NEW_FILES" ]; then
    cp "$OLDPWD/$NEW_FILES/ocws_bridge.c" "src/ocws_bridge.c"
    # Automatically update meson.build to include the new file
    # This assumes fuzzel uses meson and looks for src/fuzzel.c
    sed -i '/src\/fuzzel.c/a \  "src\/ocws_bridge.c",' meson.build
else
    echo "Error: $NEW_FILES directory not found."
    exit 1
fi

# 4. Compile
echo "🔨 Compiling custom binary..."
# Assuming dependencies like meson and ninja are installed
if ! command -v meson &> /dev/null || ! command -v ninja &> /dev/null; then
    echo "Error: meson or ninja not found. Please install build dependencies."
    exit 1
fi

meson setup build
ninja -C build

# 5. Finalize
echo "✅ Build Complete!"
echo "Binary location: $BUILD_DIR/build/fuzzel"
echo "To install: sudo cp $BUILD_DIR/build/fuzzel /usr/local/bin/fuzzel"
