#!/usr/bin/env bash
#
# run-all-tests.sh - Run all validation tests
#
# Usage:
#   ./run-all-tests.sh           # Run all tests
#   ./run-all-tests.sh --verbose # Run with verbose output
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# Test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

VERBOSE=""
[[ "${1:-}" == "--verbose" ]] || [[ "${1:-}" == "-v" ]] && VERBOSE="--verbose"

echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  Python Environment Management Tests${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""

# Run each test suite
for test_script in "$SCRIPT_DIR"/test-*.sh; do
    if [[ -f "$test_script" ]] && [[ -x "$test_script" ]]; then
        suite_name=$(basename "$test_script" .sh)
        ((TOTAL_SUITES++))

        echo -e "${BOLD}Running: $suite_name${NC}"
        echo "--------------------------------------------"

        if "$test_script" $VERBOSE; then
            ((PASSED_SUITES++))
            echo ""
        else
            ((FAILED_SUITES++))
            echo ""
        fi
    fi
done

# Summary
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  Final Summary${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""
echo "Test suites run:    $TOTAL_SUITES"
echo -e "Test suites passed: ${GREEN}$PASSED_SUITES${NC}"

if [[ $FAILED_SUITES -gt 0 ]]; then
    echo -e "Test suites failed: ${RED}$FAILED_SUITES${NC}"
    echo ""
    echo -e "${RED}FAILED${NC} - Some tests did not pass"
    exit 1
else
    echo ""
    echo -e "${GREEN}SUCCESS${NC} - All test suites passed"
    exit 0
fi
