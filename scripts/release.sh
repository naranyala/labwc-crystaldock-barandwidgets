#!/bin/bash
# OCWS Release Builder
# Builds for all architectures and creates release archives

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/dist"
VERSION="${1:-$(date +%Y%m%d)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass()  { echo -e "${GREEN}✓${NC} $1"; }
info()  { echo -e "${CYAN}→${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; exit 1; }

# Targets
TARGETS=(
    "x86_64-linux-musl"
    "aarch64-linux-musl"
    "riscv64-linux-musl"
)

echo ""
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}       OCWS Release Builder v${VERSION}${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build each target
for target in "${TARGETS[@]}"; do
    info "Building for $target..."
    
    if zig build -Dtarget="$target" -Doptimize=ReleaseFast 2>/dev/null; then
        # Create archive
        ARCHIVE="$BUILD_DIR/ocws-${target}-v${VERSION}.tar.gz"
        tar -czf "$ARCHIVE" -C zig-out/bin .
        pass "Created: $(basename "$ARCHIVE")"
    else
        fail "Failed to build for $target"
    fi
done

# Create source archive
info "Creating source archive..."
cd "$PROJECT_DIR/.."
tar -czf "$BUILD_DIR/ocws-source-v${VERSION}.tar.gz" \
    --exclude='.git' \
    --exclude='zig-out' \
    --exclude='.zig-cache' \
    --exclude='dist' \
    "$(basename "$PROJECT_DIR")"
pass "Created: ocws-source-v${VERSION}.tar.gz"

# Summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}           Build Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Artifacts in: $BUILD_DIR"
ls -lh "$BUILD_DIR"
echo ""
echo "To install locally:"
echo "  sudo cp zig-out/bin/ocws* /usr/local/bin/"
echo ""
echo "To create GitHub release:"
echo "  gh release create v${VERSION} $BUILD_DIR/*.tar.gz"
