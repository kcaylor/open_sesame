#!/usr/bin/env bash
#
# test-env-sync.sh - Validation tests for env-sync.sh
#
# Usage:
#   ./test-env-sync.sh           # Run all tests
#   ./test-env-sync.sh --verbose # Run with verbose output
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_SYNC="$REPO_ROOT/.specify/scripts/bash/env-sync.sh"

# Test state
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# =============================================================================
# Test Framework
# =============================================================================

log() {
    [[ "$VERBOSE" == "true" ]] && echo "$*"
}

pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}FAIL${NC}: $1"
    [[ -n "${2:-}" ]] && echo "  Details: $2"
}

skip() {
    echo -e "${YELLOW}SKIP${NC}: $1"
}

run_test() {
    local name="$1"
    local func="$2"
    ((TESTS_RUN++))
    log "Running: $name"
    if $func; then
        pass "$name"
    else
        fail "$name"
    fi
}

# =============================================================================
# Tests
# =============================================================================

test_script_exists() {
    [[ -f "$ENV_SYNC" ]]
}

test_script_executable() {
    [[ -x "$ENV_SYNC" ]]
}

test_help_flag() {
    "$ENV_SYNC" --help >/dev/null 2>&1
}

test_help_contains_usage() {
    "$ENV_SYNC" --help 2>&1 | grep -q "USAGE"
}

test_help_contains_options() {
    "$ENV_SYNC" --help 2>&1 | grep -q "OPTIONS"
}

test_help_contains_workflow() {
    "$ENV_SYNC" --help 2>&1 | grep -q "WORKFLOW"
}

test_invalid_option_fails() {
    ! "$ENV_SYNC" --invalid-option >/dev/null 2>&1
}

test_sources_common() {
    grep -q "source.*common.sh" "$ENV_SYNC"
}

test_has_auto_mode() {
    grep -q "\-\-auto" "$ENV_SYNC"
}

test_has_json_mode() {
    grep -q "\-\-json" "$ENV_SYNC"
}

test_has_package_mode() {
    grep -q "\-\-package" "$ENV_SYNC"
}

test_has_pip_detection() {
    grep -q "get_pip_packages" "$ENV_SYNC"
}

test_has_conda_detection() {
    grep -q "get_conda_packages" "$ENV_SYNC"
}

test_has_pixi_detection() {
    grep -q "get_pixi_packages" "$ENV_SYNC"
}

test_loads_config() {
    grep -q "load_config" "$ENV_SYNC"
}

test_has_package_comparison() {
    grep -q "compare_packages" "$ENV_SYNC"
}

test_has_package_documentation() {
    grep -q "document_package" "$ENV_SYNC"
}

test_updates_env_config() {
    grep -q "update_env_config" "$ENV_SYNC"
}

test_has_json_output() {
    grep -q "output_json" "$ENV_SYNC"
}

test_json_has_status() {
    grep -q '"status"' "$ENV_SYNC"
}

test_json_has_packages() {
    grep -q '"new_packages"' "$ENV_SYNC"
}

test_has_cleanup() {
    grep -q "trap cleanup" "$ENV_SYNC"
}

test_has_error_handling() {
    grep -q "set -euo pipefail" "$ENV_SYNC"
}

test_has_colored_output() {
    grep -q "setup_colors" "$ENV_SYNC"
}

test_normalizes_package_names() {
    grep -q "normalize_package_name" "$ENV_SYNC"
}

test_no_command_injection_risks() {
    local risky_patterns=(
        'eval "\$'
        '\$(\$'
    )
    for pattern in "${risky_patterns[@]}"; do
        if grep -qE "$pattern" "$ENV_SYNC"; then
            return 1
        fi
    done
    return 0
}

test_uses_temp_files_safely() {
    grep -q "mktemp" "$ENV_SYNC"
}

# =============================================================================
# Main
# =============================================================================

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    echo "=========================================="
    echo "Validation Tests: env-sync.sh"
    echo "=========================================="
    echo ""

    # Basic tests
    run_test "Script exists" test_script_exists
    run_test "Script is executable" test_script_executable
    run_test "Help flag works" test_help_flag
    run_test "Help contains USAGE section" test_help_contains_usage
    run_test "Help contains OPTIONS section" test_help_contains_options
    run_test "Help contains WORKFLOW section" test_help_contains_workflow
    run_test "Invalid option fails" test_invalid_option_fails

    # Structure tests
    run_test "Sources common.sh" test_sources_common
    run_test "Loads configuration" test_loads_config

    # Feature tests
    run_test "Has --auto mode" test_has_auto_mode
    run_test "Has --json mode" test_has_json_mode
    run_test "Has --package mode" test_has_package_mode

    # Package detection
    run_test "Has pip package detection" test_has_pip_detection
    run_test "Has conda package detection" test_has_conda_detection
    run_test "Has pixi package detection" test_has_pixi_detection
    run_test "Has package comparison" test_has_package_comparison
    run_test "Normalizes package names" test_normalizes_package_names

    # Documentation
    run_test "Has package documentation" test_has_package_documentation
    run_test "Updates .env-config" test_updates_env_config

    # JSON output
    run_test "Has JSON output function" test_has_json_output
    run_test "JSON includes status" test_json_has_status
    run_test "JSON includes packages" test_json_has_packages

    # Quality tests
    run_test "Has colored output support" test_has_colored_output
    run_test "Has error handling (set -euo pipefail)" test_has_error_handling
    run_test "Has cleanup trap" test_has_cleanup
    run_test "Uses temp files safely" test_uses_temp_files_safely

    # Security tests
    run_test "No obvious command injection risks" test_no_command_injection_risks

    # Summary
    echo ""
    echo "=========================================="
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}$TESTS_FAILED tests failed${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed${NC}"
        exit 0
    fi
}

main "$@"
