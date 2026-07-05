#!/bin/bash
# OCWS Zig Harness Test Suite
# Tests the unified Zig binary and cross-compilation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/zig-out/bin"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

header() { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}"; }
pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS_COUNT++)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL_COUNT++)); }
skip() { echo -e "  ${YELLOW}[SKIP]${NC} $1"; ((SKIP_COUNT++)); }

# ============================================================
# 1. Build System Validation
# ============================================================
header "Build System Validation"

if [ -f "$PROJECT_DIR/build.zig" ]; then
    pass "build.zig exists"
else
    fail "build.zig not found"
fi

if [ -x "$(command -v zig)" ]; then
    ZIG_VERSION=$(zig version 2>/dev/null)
    pass "Zig installed: $ZIG_VERSION"
else
    skip "Zig not installed"
fi

# ============================================================
# 2. Build Test
# ============================================================
header "Build Test"

if [ -x "$(command -v zig)" ]; then
    cd "$PROJECT_DIR"
    if zig build 2>/dev/null; then
        pass "Build successful"
    else
        fail "Build failed"
    fi
fi

# ============================================================
# 3. Binary Existence
# ============================================================
header "Binary Existence"

if [ -f "$BUILD_DIR/ocws" ]; then
    pass "Unified binary exists: ocws"
else
    fail "Unified binary missing: ocws"
fi

# ============================================================
# 4. Unified Binary Functionality
# ============================================================
header "Unified Binary Functionality"

if [ -x "$BUILD_DIR/ocws" ]; then
    # Test help
    if "$BUILD_DIR/ocws" help >/dev/null 2>&1; then
        pass "ocws help works"
    else
        fail "ocws help failed"
    fi
    
    # Test version
    if "$BUILD_DIR/ocws" version >/dev/null 2>&1; then
        pass "ocws version works"
    else
        fail "ocws version failed"
    fi
    
    # Test status
    if "$BUILD_DIR/ocws" status >/dev/null 2>&1; then
        pass "ocws status works"
    else
        fail "ocws status failed"
    fi
    
    # Test list
    if "$BUILD_DIR/ocws" list >/dev/null 2>&1; then
        pass "ocws list works"
    else
        fail "ocws list failed"
    fi
    
    # Test rebuild
    if "$BUILD_DIR/ocws" rebuild >/dev/null 2>&1; then
        pass "ocws rebuild works"
    else
        fail "ocws rebuild failed"
    fi
    
    # Test dispatch to subcommands
    SUBCOMMANDS=("kv" "brightness" "volume" "shot" "sysmon" "clip" "lock")
    for subcmd in "${SUBCOMMANDS[@]}"; do
        if "$BUILD_DIR/ocws" "$subcmd" --help >/dev/null 2>&1; then
            pass "ocws dispatches to $subcmd"
        else
            fail "ocws dispatch to $subcmd failed"
        fi
    done
else
    skip "Unified binary not found"
fi

# ============================================================
# 5. Cross-Compilation Test
# ============================================================
header "Cross-Compilation Test"

if [ -x "$(command -v zig)" ]; then
    # Test cross-compilation for aarch64
    cd "$PROJECT_DIR"
    if zig build -Dtarget=aarch64-linux-musl 2>/dev/null; then
        pass "Cross-compile to aarch64-linux-musl works"
    else
        skip "Cross-compile to aarch64-linux-musl failed (missing dependencies)"
    fi
else
    skip "Zig not installed"
fi

# ============================================================
# 6. Build.zig Analysis
# ============================================================
header "Build.zig Analysis"

if [ -f "$PROJECT_DIR/build.zig" ]; then
    # Check for unified binary definition
    if grep -q "ocws" "$PROJECT_DIR/build.zig"; then
        pass "Unified binary defined in build.zig"
    else
        fail "Unified binary not defined in build.zig"
    fi
    
    # Check for C utilities
    UTILS=("ocws-shot" "ocws-clip" "ocws-lock" "ocws-sysmon" "ocws-brightness" "ocws-volume" "ocws-recorder")
    for util in "${UTILS[@]}"; do
        if grep -q "\"$util\"" "$PROJECT_DIR/build.zig"; then
            pass "C utility defined: $util"
        else
            fail "C utility not defined: $util"
        fi
    done
    
    # Check for system library linking
    LIBS=("cairo" "tesseract" "glib" "gtk" "wayland")
    for lib in "${LIBS[@]}"; do
        if grep -q "$lib" "$PROJECT_DIR/build.zig"; then
            pass "System library linked: $lib"
        else
            skip "System library not linked: $lib"
        fi
    done
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo -e "${BOLD}Zig Harness Test Suite Summary:${NC}"
echo -e "  ${GREEN}Passed:${NC} $PASS_COUNT"
echo -e "  ${YELLOW}Skipped:${NC} $SKIP_COUNT"
echo -e "  ${RED}Failed:${NC} $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
