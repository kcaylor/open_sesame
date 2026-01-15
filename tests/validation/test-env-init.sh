#!/usr/bin/env bash
#
# test-env-init.sh - Validation tests for env-init.sh
#
# Usage:
#   ./test-env-init.sh           # Run all tests
#   ./test-env-init.sh --verbose # Run with verbose output
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_INIT="$REPO_ROOT/.specify/scripts/bash/env-init.sh"

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
    [[ -f "$ENV_INIT" ]]
}

test_script_executable() {
    [[ -x "$ENV_INIT" ]]
}

test_help_flag() {
    "$ENV_INIT" --help >/dev/null 2>&1
}

test_help_contains_usage() {
    "$ENV_INIT" --help 2>&1 | grep -q "USAGE"
}

test_help_contains_options() {
    "$ENV_INIT" --help 2>&1 | grep -q "OPTIONS"
}

test_help_contains_examples() {
    "$ENV_INIT" --help 2>&1 | grep -q "EXAMPLES"
}

test_invalid_option_fails() {
    ! "$ENV_INIT" --invalid-option >/dev/null 2>&1
}

test_sources_common() {
    grep -q "source.*common.sh" "$ENV_INIT"
}

test_has_platform_detection() {
    grep -q "detect_platform" "$ENV_INIT"
}

test_has_tool_detection() {
    grep -q "detect_tools" "$ENV_INIT"
}

test_has_pixi_support() {
    grep -q "create_pixi_environment" "$ENV_INIT"
}

test_has_conda_support() {
    grep -q "create_conda_environment" "$ENV_INIT"
}

test_has_venv_support() {
    grep -q "create_venv_environment" "$ENV_INIT"
}

test_has_from_config_mode() {
    grep -q "\-\-from-config" "$ENV_INIT"
}

test_has_quiet_mode() {
    grep -q "\-\-quiet" "$ENV_INIT"
}

test_has_tool_flag() {
    grep -q "\-\-tool" "$ENV_INIT"
}

test_has_python_version_flag() {
    grep -q "\-\-python-version" "$ENV_INIT"
}

test_creates_env_config() {
    grep -q "create_env_config" "$ENV_INIT"
}

test_updates_gitignore() {
    grep -q "update_gitignore" "$ENV_INIT"
}

test_has_colored_output() {
    grep -q "setup_colors" "$ENV_INIT"
}

test_has_error_handling() {
    grep -q "set -euo pipefail" "$ENV_INIT"
}

test_validates_python_version() {
    grep -q "validate_python_version" "$ENV_INIT"
}

test_no_command_injection_risks() {
    # Check for potential command injection patterns
    # Should not have unquoted variables in dangerous contexts
    local risky_patterns=(
        'eval "\$'      # eval with unquoted var
        '\$(\$'         # nested unquoted command substitution
    )
    for pattern in "${risky_patterns[@]}"; do
        if grep -qE "$pattern" "$ENV_INIT"; then
            return 1
        fi
    done
    return 0
}

test_uses_quoted_variables() {
    # Count unquoted $VAR usages (simplified check)
    # This is a heuristic - not all unquoted vars are problems
    local unquoted_count=$(grep -cE '\$[A-Z_]+[^"}]' "$ENV_INIT" 2>/dev/null || echo 0)
    # Allow some - many are safe in specific contexts
    [[ $unquoted_count -lt 50 ]]
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
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
    echo "Validation Tests: env-init.sh"
    echo "=========================================="
    echo ""

    # Basic tests
    run_test "Script exists" test_script_exists
    run_test "Script is executable" test_script_executable
    run_test "Help flag works" test_help_flag
    run_test "Help contains USAGE section" test_help_contains_usage
    run_test "Help contains OPTIONS section" test_help_contains_options
    run_test "Help contains EXAMPLES section" test_help_contains_examples
    run_test "Invalid option fails" test_invalid_option_fails

    # Structure tests
    run_test "Sources common.sh" test_sources_common
    run_test "Has platform detection" test_has_platform_detection
    run_test "Has tool detection" test_has_tool_detection

    # Feature tests
    run_test "Has pixi support" test_has_pixi_support
    run_test "Has conda support" test_has_conda_support
    run_test "Has venv support" test_has_venv_support
    run_test "Has --from-config mode" test_has_from_config_mode
    run_test "Has --quiet mode" test_has_quiet_mode
    run_test "Has --tool flag" test_has_tool_flag
    run_test "Has --python-version flag" test_has_python_version_flag

    # Configuration tests
    run_test "Creates .env-config" test_creates_env_config
    run_test "Updates .gitignore" test_updates_gitignore

    # Quality tests
    run_test "Has colored output support" test_has_colored_output
    run_test "Has error handling (set -euo pipefail)" test_has_error_handling
    run_test "Validates Python version" test_validates_python_version

    # Security tests
    run_test "No obvious command injection risks" test_no_command_injection_risks
    run_test "Uses quoted variables (heuristic)" test_uses_quoted_variables

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
