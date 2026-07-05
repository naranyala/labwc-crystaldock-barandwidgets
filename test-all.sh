#!/bin/bash
# OCWS Complete Test Suite
# Runs all test suites and aggregates pass/skip/fail counts

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
SUITES_RAN=0
SUITES_FAILED=0

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}              OCWS Complete Test Suite                          ${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ----------------------------------------------------------------
# run_suite <path>
#   Runs the suite and extracts per-suite pass/skip/fail counts
#   by capturing the "Summary" block at the end.
#   Returns exit code 0 (suite passed) or 1 (suite had failures).
# ----------------------------------------------------------------
run_suite() {
    local suite_path="$1"
    local suite_name
    suite_name="$(basename "$suite_path")"

    echo -e "${BOLD}─────────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}Running: $suite_name${NC}"
    echo ""

    # Capture full output while also streaming it
    local tmpout
    tmpout=$(mktemp)
    local exit_code=0
    bash "$suite_path" 2>&1 | tee "$tmpout" || exit_code=$?

    # Parse summary counts from the sub-suite output
    # Expected format (emitted by every sub-suite):
    #   Passed:  N
    #   Skipped: N
    #   Failed:  N
    local s_pass s_skip s_fail
    s_pass=$(grep -oP '(?i)Passed[^:]*:\s*\K[0-9]+' "$tmpout" | tail -1 || echo 0)
    s_skip=$(grep -oP '(?i)Skipped[^:]*:\s*\K[0-9]+' "$tmpout" | tail -1 || echo 0)
    s_fail=$(grep -oP '(?i)Failed[^:]*:\s*\K[0-9]+' "$tmpout" | tail -1 || echo 0)

    # Fallback: count [PASS]/[SKIP]/[FAIL] lines directly
    if [ "${s_pass:-0}" = "0" ] && [ "${s_skip:-0}" = "0" ] && [ "${s_fail:-0}" = "0" ]; then
        s_pass=$(grep -c '\[PASS\]' "$tmpout" 2>/dev/null || echo 0)
        s_skip=$(grep -c '\[SKIP\]' "$tmpout" 2>/dev/null || echo 0)
        s_fail=$(grep -c '\[FAIL\]' "$tmpout" 2>/dev/null || echo 0)
    fi

    TOTAL_PASS=$(( TOTAL_PASS + ${s_pass:-0} ))
    TOTAL_SKIP=$(( TOTAL_SKIP + ${s_skip:-0} ))
    TOTAL_FAIL=$(( TOTAL_FAIL + ${s_fail:-0} ))
    SUITES_RAN=$(( SUITES_RAN + 1 ))

    rm -f "$tmpout"

    echo ""
    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ $suite_name passed${NC}  (pass=${s_pass:-0} skip=${s_skip:-0} fail=${s_fail:-0})"
    else
        echo -e "${RED}✗ $suite_name FAILED${NC}  (pass=${s_pass:-0} skip=${s_skip:-0} fail=${s_fail:-0})"
        SUITES_FAILED=$(( SUITES_FAILED + 1 ))
    fi
    echo ""
    return "$exit_code"
}

# ----------------------------------------------------------------
# Suite discovery — run in a defined order
# ----------------------------------------------------------------
TEST_SUITES=(
    "test-bash-scripts.sh"
    "test-c-binaries.sh"
    "test-zig-harness.sh"
    "test-widgets.sh"
)

for suite in "${TEST_SUITES[@]}"; do
    # Prefer tests/ subdirectory, fall back to project root
    SUITE_PATH="$TESTS_DIR/$suite"
    ROOT_PATH="$SCRIPT_DIR/$suite"

    if [ -f "$SUITE_PATH" ]; then
        run_suite "$SUITE_PATH" || true
    elif [ -f "$ROOT_PATH" ]; then
        run_suite "$ROOT_PATH" || true
    else
        echo -e "${YELLOW}⚠ $suite not found — skipping${NC}"
        echo ""
        TOTAL_SKIP=$(( TOTAL_SKIP + 1 ))
    fi
done

# ----------------------------------------------------------------
# Grand summary
# ----------------------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}                    Grand Test Summary                          ${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Suites run:   $SUITES_RAN"
echo -e "  ${GREEN}Tests passed:${NC}  $TOTAL_PASS"
echo -e "  ${YELLOW}Tests skipped:${NC} $TOTAL_SKIP"
echo -e "  ${RED}Tests failed:${NC}  $TOTAL_FAIL"
echo ""

if [ "$TOTAL_FAIL" -gt 0 ] || [ "$SUITES_FAILED" -gt 0 ]; then
    echo -e "${RED}${BOLD}✗ Some tests failed! ($SUITES_FAILED suite(s) had failures, $TOTAL_FAIL individual test(s) failed)${NC}"
    exit 1
else
    echo -e "${GREEN}${BOLD}✓ All tests passed!${NC}"
    exit 0
fi
