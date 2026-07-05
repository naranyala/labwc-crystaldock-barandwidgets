#!/bin/bash
# OCWS Cross-Compilation Helper
# Build for specific architectures
#
# Note: Only binaries without external dependencies can be cross-compiled.
# Binaries requiring GTK, Cairo, Tesseract, etc. need cross-compilation sysroot.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass()  { echo -e "${GREEN}✓${NC} $1"; }
info()  { echo -e "${CYAN}→${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; exit 1; }

usage() {
    cat <<EOF
${CYAN}OCWS Cross-Compilation Helper${NC}

Usage: $0 <target> [optimize]

Targets:
  x86_64-linux       x86_64 Linux (musl)
  aarch64-linux      ARM64 Linux (musl)
  riscv64-linux      RISC-V Linux (musl)
  x86_64-freebsd     x86_64 FreeBSD
  all                Build all targets

Optimize:
  Debug              Debug build (default)
  ReleaseSafe        Safe optimizations
  ReleaseFast        Fast optimizations
  ReleaseSmall       Small binary size

Examples:
  $0 x86_64-linux
  $0 aarch64-linux ReleaseFast
  $0 all ReleaseFast

Note: Cross-compilation only works for binaries without external dependencies.
Binaries requiring GTK, Cairo, Tesseract, etc. need cross-compilation sysroot.

EOF
    exit 0
}

[ $# -eq 0 ] && usage

TARGET="$1"
OPTIMIZE="${2:-Debug}"

cd "$PROJECT_DIR"

case "$TARGET" in
    x86_64-linux)
        TARGET_ZIG="x86_64-linux-musl"
        ;;
    aarch64-linux)
        TARGET_ZIG="aarch64-linux-musl"
        ;;
    riscv64-linux)
        TARGET_ZIG="riscv64-linux-musl"
        ;;
    x86_64-freebsd)
        TARGET_ZIG="x86_64-freebsd"
        ;;
    all)
        info "Building all targets (no external deps)..."
        for t in x86_64-linux-musl aarch64-linux-musl riscv64-linux-musl; do
            info "Building $t..."
            zig build -Dtarget="$t" -Doptimize="$OPTIMIZE" 2>/dev/null && \
                pass "Built $t" || warn "Failed $t"
        done
        exit 0
        ;;
    *)
        fail "Unknown target: $TARGET (use --help for list)"
        ;;
esac

info "Building for $TARGET_ZIG with $OPTIMIZE optimization..."

if zig build -Dtarget="$TARGET_ZIG" -Doptimize="$OPTIMIZE"; then
    pass "Build successful!"
    echo ""
    info "Binaries:"
    ls -lh zig-out/bin/ocws*
    echo ""
    info "To install:"
    echo "  sudo cp zig-out/bin/ocws* /usr/local/bin/"
else
    fail "Build failed"
fi
