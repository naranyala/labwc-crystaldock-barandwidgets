#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; }
fail() { echo -e "${RED}✗ FAIL${NC}: $1"; exit 1; }

echo -e "${BOLD}Running Bash Test Suite...${NC}"

# Test theme-engine preview
if ./scripts/theme-engine.sh preview themes/catppuccin-mocha.ini > /dev/null; then
    pass "theme-engine.sh preview executes successfully"
else
    fail "theme-engine.sh preview crashed"
fi

# Test theme-engine list
if ./scripts/theme-engine.sh list | grep "catppuccin-mocha" > /dev/null; then
    pass "theme-engine.sh list finds Catppuccin Mocha"
else
    fail "theme-engine.sh list did not find Catppuccin Mocha"
fi

echo -e "${BOLD}All bash tests passed!${NC}"
