#!/usr/bin/env bash
#
# test-env-validate.sh - Validation tests for env-validate.sh
#
# Usage:
#   ./test-env-validate.sh           # Run all tests
#   ./test-env-validate.sh --verbose # Run with verbose output
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_VALIDATE="$REPO_ROOT/.specify/scripts/bash/env-validate.sh"

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
    [[ -f "$ENV_VALIDATE" ]]
}

test_script_executable() {
    [[ -x "$ENV_VALIDATE" ]]
}

test_help_flag() {
    "$ENV_VALIDATE" --help >/dev/null 2>&1
}

test_help_contains_usage() {
    "$ENV_VALIDATE" --help 2>&1 | grep -q "USAGE"
}

test_help_contains_exit_codes() {
    "$ENV_VALIDATE" --help 2>&1 | grep -q "EXIT CODES"
}

test_help_contains_json_output() {
    "$ENV_VALIDATE" --help 2>&1 | grep -q "JSON OUTPUT"
}

test_invalid_option_fails() {
    ! "$ENV_VALIDATE" --invalid-option >/dev/null 2>&1
}

test_sources_common() {
    grep -q "source.*common.sh" "$ENV_VALIDATE"
}

test_has_json_mode() {
    grep -q "\-\-json" "$ENV_VALIDATE"
}

test_has_quiet_mode() {
    grep -q "\-\-quiet" "$ENV_VALIDATE"
}

test_has_fix_mode() {
    grep -q "\-\-fix" "$ENV_VALIDATE"
}

test_defines_exit_codes() {
    grep -q "EXIT_ACTIVE" "$ENV_VALIDATE" && \
    grep -q "EXIT_INACTIVE" "$ENV_VALIDATE" && \
    grep -q "EXIT_MISMATCH" "$ENV_VALIDATE" && \
    grep -q "EXIT_MISSING_DEPS" "$ENV_VALIDATE" && \
    grep -q "EXIT_ERROR" "$ENV_VALIDATE"
}

test_has_activation_check() {
    grep -q "check_activation" "$ENV_VALIDATE"
}

test_has_python_version_check() {
    grep -q "check_python_version" "$ENV_VALIDATE"
}

test_has_dependency_check() {
    grep -q "check_dependencies" "$ENV_VALIDATE"
}

test_has_status_determination() {
    grep -q "determine_status" "$ENV_VALIDATE"
}

test_has_json_output() {
    grep -q "output_json" "$ENV_VALIDATE"
}

test_json_has_status() {
    grep -q '"status"' "$ENV_VALIDATE"
}

test_json_has_environment() {
    grep -q '"environment"' "$ENV_VALIDATE"
}

test_json_has_issues() {
    grep -q '"issues"' "$ENV_VALIDATE"
}

test_has_fix_function() {
    grep -q "attempt_fixes" "$ENV_VALIDATE"
}

test_has_remediation_suggestions() {
    grep -q "Suggested Actions" "$ENV_VALIDATE"
}

test_has_activation_help() {
    grep -q "show_activation_help" "$ENV_VALIDATE"
}

test_has_error_handling() {
    grep -q "set -euo pipefail" "$ENV_VALIDATE"
}

test_has_colored_output() {
    grep -q "setup_colors" "$ENV_VALIDATE"
}

test_checks_pixi_environment() {
    grep -q "\.pixi" "$ENV_VALIDATE"
}

test_checks_conda_environment() {
    grep -q "CONDA_DEFAULT_ENV\|CONDA_PREFIX" "$ENV_VALIDATE"
}

test_checks_venv_environment() {
    grep -q "VIRTUAL_ENV" "$ENV_VALIDATE"
}

test_no_command_injection_risks() {
    local risky_patterns=(
        'eval "\$'
        '\$(\$'
    )
    for pattern in "${risky_patterns[@]}"; do
        if grep -qE "$pattern" "$ENV_VALIDATE"; then
            return 1
        fi
    done
    return 0
}

test_loads_config() {
    grep -q "load_config" "$ENV_VALIDATE"
}

test_tracks_issues() {
    grep -q "add_issue" "$ENV_VALIDATE"
}

test_tracks_warnings() {
    grep -q "add_warning" "$ENV_VALIDATE"
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
    echo "Validation Tests: env-validate.sh"
    echo "=========================================="
    echo ""

    # Basic tests
    run_test "Script exists" test_script_exists
    run_test "Script is executable" test_script_executable
    run_test "Help flag works" test_help_flag
    run_test "Help contains USAGE section" test_help_contains_usage
    run_test "Help contains EXIT CODES section" test_help_contains_exit_codes
    run_test "Help contains JSON OUTPUT section" test_help_contains_json_output
    run_test "Invalid option fails" test_invalid_option_fails

    # Structure tests
    run_test "Sources common.sh" test_sources_common
    run_test "Loads configuration" test_loads_config

    # Feature tests
    run_test "Has --json mode" test_has_json_mode
    run_test "Has --quiet mode" test_has_quiet_mode
    run_test "Has --fix mode" test_has_fix_mode
    run_test "Defines exit codes" test_defines_exit_codes

    # Validation checks
    run_test "Has activation check" test_has_activation_check
    run_test "Has Python version check" test_has_python_version_check
    run_test "Has dependency check" test_has_dependency_check
    run_test "Has status determination" test_has_status_determination
    run_test "Tracks issues" test_tracks_issues
    run_test "Tracks warnings" test_tracks_warnings

    # Environment support
    run_test "Checks pixi environment" test_checks_pixi_environment
    run_test "Checks conda environment" test_checks_conda_environment
    run_test "Checks venv environment" test_checks_venv_environment

    # JSON output
    run_test "Has JSON output function" test_has_json_output
    run_test "JSON includes status" test_json_has_status
    run_test "JSON includes environment" test_json_has_environment
    run_test "JSON includes issues" test_json_has_issues

    # Fix mode
    run_test "Has fix function" test_has_fix_function
    run_test "Has remediation suggestions" test_has_remediation_suggestions
    run_test "Has activation help" test_has_activation_help

    # Quality tests
    run_test "Has colored output support" test_has_colored_output
    run_test "Has error handling (set -euo pipefail)" test_has_error_handling

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
