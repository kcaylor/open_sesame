#!/usr/bin/env bash
#
# env-validate.sh - Python Environment Validation Script
# Part of the res_spec Python Environment Management feature
#
# This script validates that the current environment matches the specification,
# checking activation status, Python version, and installed dependencies.
#
# Usage:
#   ./env-validate.sh                # Full validation with colored output
#   ./env-validate.sh --json         # Output as JSON for agent integration
#   ./env-validate.sh --quiet        # Quiet mode for CI (exit code only)
#   ./env-validate.sh --fix          # Attempt to fix issues automatically
#   ./env-validate.sh --help         # Show usage information
#
# Exit codes:
#   0 - ACTIVE: Environment is valid and active
#   1 - ERROR: Configuration or script error
#   2 - INACTIVE: Environment not activated
#   3 - MISMATCH: Python version mismatch
#   4 - MISSING_DEPS: Missing dependencies
#

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Exit codes
EXIT_ACTIVE=0
EXIT_ERROR=1
EXIT_INACTIVE=2
EXIT_MISMATCH=3
EXIT_MISSING_DEPS=4

# Script state
JSON_MODE=false
QUIET_MODE=false
FIX_MODE=false
NO_COLOR=false

# Validation results
VALIDATION_STATUS="UNKNOWN"
ISSUES=()
WARNINGS=()

# Environment info
ENV_TOOL=""
ENV_NAME=""
EXPECTED_PYTHON=""
ACTUAL_PYTHON=""

# =============================================================================
# Color and Output Functions
# =============================================================================

supports_color() {
    if [[ "$NO_COLOR" == "true" ]] || [[ -n "${NO_COLOR:-}" ]]; then
        return 1
    fi
    if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
        return 0
    fi
    return 1
}

setup_colors() {
    if supports_color; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''
    fi
}

info() { [[ "$QUIET_MODE" != "true" ]] && [[ "$JSON_MODE" != "true" ]] && echo -e "${BLUE}[INFO]${NC} $*"; return 0; }
success() { [[ "$QUIET_MODE" != "true" ]] && [[ "$JSON_MODE" != "true" ]] && echo -e "${GREEN}[OK]${NC} $*"; return 0; }
warn() { [[ "$QUIET_MODE" != "true" ]] && [[ "$JSON_MODE" != "true" ]] && echo -e "${YELLOW}[WARN]${NC} $*"; return 0; }
fail() { [[ "$QUIET_MODE" != "true" ]] && [[ "$JSON_MODE" != "true" ]] && echo -e "${RED}[FAIL]${NC} $*"; return 0; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header() { [[ "$QUIET_MODE" != "true" ]] && [[ "$JSON_MODE" != "true" ]] && echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; return 0; }

# Add issue to list
add_issue() {
    ISSUES+=("$1")
}

add_warning() {
    WARNINGS+=("$1")
}

# =============================================================================
# Configuration Loading
# =============================================================================

load_config() {
    local repo_root=$(get_repo_root)
    local config_file="$repo_root/.env-config"

    if [[ ! -f "$config_file" ]]; then
        add_issue "Configuration file .env-config not found"
        return 1
    fi

    # Parse config file
    ENV_TOOL=$(grep -E "^tool\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ' || echo "")
    ENV_NAME=$(grep -E "^env_name\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ' || echo "")
    EXPECTED_PYTHON=$(grep -E "^python_version\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ' || echo "")

    if [[ -z "$ENV_TOOL" ]]; then
        add_issue "Missing 'tool' in .env-config"
        return 1
    fi

    return 0
}

# =============================================================================
# Validation Functions
# =============================================================================

# Check if environment is activated
check_activation() {
    local repo_root=$(get_repo_root)

    case "$ENV_TOOL" in
        pixi)
            # Pixi doesn't require activation for running commands
            # Check if .pixi directory exists
            if [[ -d "$repo_root/.pixi" ]]; then
                success "Pixi environment installed"
                return 0
            else
                add_issue "Pixi environment not installed (run 'pixi install')"
                return 1
            fi
            ;;
        conda|mamba)
            # Check CONDA_DEFAULT_ENV or CONDA_PREFIX
            if [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
                if [[ "$CONDA_DEFAULT_ENV" == "$ENV_NAME" ]]; then
                    success "Conda environment '$ENV_NAME' is active"
                    return 0
                else
                    add_issue "Wrong conda environment active: '$CONDA_DEFAULT_ENV' (expected '$ENV_NAME')"
                    return 1
                fi
            else
                add_issue "No conda environment is activated"
                return 1
            fi
            ;;
        venv)
            # Check VIRTUAL_ENV
            if [[ -n "${VIRTUAL_ENV:-}" ]]; then
                local venv_name=$(basename "$VIRTUAL_ENV")
                success "Virtual environment '$venv_name' is active"
                return 0
            else
                # Check if venv exists but not activated
                if [[ -d "$repo_root/venv" ]]; then
                    add_issue "Virtual environment exists but is not activated"
                    return 1
                else
                    add_issue "Virtual environment not found"
                    return 1
                fi
            fi
            ;;
        *)
            add_issue "Unknown environment tool: $ENV_TOOL"
            return 1
            ;;
    esac
}

# Check Python version
check_python_version() {
    if [[ -z "$EXPECTED_PYTHON" ]]; then
        add_warning "No python_version specified in .env-config"
        return 0
    fi

    # Get actual Python version
    local python_cmd=""
    local repo_root=$(get_repo_root)

    case "$ENV_TOOL" in
        pixi)
            # Use pixi run python
            if command -v pixi &>/dev/null; then
                ACTUAL_PYTHON=$(pixi run python --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "")
            fi
            ;;
        conda|mamba)
            if [[ -n "${CONDA_PREFIX:-}" ]]; then
                ACTUAL_PYTHON=$("$CONDA_PREFIX/bin/python" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "")
            fi
            ;;
        venv)
            if [[ -n "${VIRTUAL_ENV:-}" ]]; then
                ACTUAL_PYTHON=$("$VIRTUAL_ENV/bin/python" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "")
            elif [[ -d "$repo_root/venv" ]]; then
                ACTUAL_PYTHON=$("$repo_root/venv/bin/python" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "")
            fi
            ;;
    esac

    if [[ -z "$ACTUAL_PYTHON" ]]; then
        add_issue "Could not determine Python version"
        return 1
    fi

    # Compare versions (major.minor)
    local expected_major_minor=$(echo "$EXPECTED_PYTHON" | grep -oE '^[0-9]+\.[0-9]+')

    if [[ "$ACTUAL_PYTHON" == "$expected_major_minor" ]]; then
        success "Python version: $ACTUAL_PYTHON (expected $expected_major_minor)"
        return 0
    else
        add_issue "Python version mismatch: $ACTUAL_PYTHON (expected $expected_major_minor)"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    local repo_root=$(get_repo_root)
    local missing=()

    case "$ENV_TOOL" in
        pixi)
            # Check pixi.lock exists and is up to date
            if [[ ! -f "$repo_root/pixi.lock" ]]; then
                add_issue "pixi.lock not found (run 'pixi install')"
                return 1
            fi

            # Compare pixi.toml modification time with pixi.lock
            if [[ -f "$repo_root/pixi.toml" ]]; then
                if [[ "$repo_root/pixi.toml" -nt "$repo_root/pixi.lock" ]]; then
                    add_warning "pixi.toml modified after pixi.lock (run 'pixi install')"
                fi
            fi

            success "Pixi dependencies installed (pixi.lock present)"
            ;;

        conda|mamba)
            # Check environment.yml packages are installed
            if [[ -f "$repo_root/environment.yml" ]]; then
                # Get list of packages from environment.yml
                local spec_packages=$(grep -E "^\s*-\s*[a-zA-Z]" "$repo_root/environment.yml" | \
                    sed 's/.*-\s*//' | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | \
                    tr -d ' ' | grep -v "^pip$" | tr '[:upper:]' '[:lower:]')

                if [[ -n "${CONDA_PREFIX:-}" ]]; then
                    local installed=$("$CONDA_PREFIX/bin/conda" list --export 2>/dev/null | \
                        grep -v "^#" | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]')

                    for pkg in $spec_packages; do
                        if ! echo "$installed" | grep -qx "$pkg"; then
                            missing+=("$pkg")
                        fi
                    done
                fi
            fi

            if [[ ${#missing[@]} -gt 0 ]]; then
                add_issue "Missing conda packages: ${missing[*]}"
                return 1
            else
                success "Conda dependencies installed"
            fi
            ;;

        venv)
            # Check requirements.txt packages are installed
            if [[ -f "$repo_root/requirements.txt" ]]; then
                local pip_cmd=""
                if [[ -n "${VIRTUAL_ENV:-}" ]]; then
                    pip_cmd="$VIRTUAL_ENV/bin/pip"
                elif [[ -f "$repo_root/venv/bin/pip" ]]; then
                    pip_cmd="$repo_root/venv/bin/pip"
                fi

                if [[ -n "$pip_cmd" ]]; then
                    local installed=$($pip_cmd freeze 2>/dev/null | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]' | tr '_' '-')

                    # Check each package in requirements.txt
                    while IFS= read -r line; do
                        # Skip comments and empty lines
                        [[ "$line" =~ ^#.*$ ]] && continue
                        [[ -z "$line" ]] && continue

                        # Extract package name
                        local pkg=$(echo "$line" | sed 's/[>=<~!].*//' | tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr -d ' ')
                        [[ -z "$pkg" ]] && continue

                        if ! echo "$installed" | grep -qx "$pkg"; then
                            missing+=("$pkg")
                        fi
                    done < "$repo_root/requirements.txt"
                fi
            fi

            if [[ ${#missing[@]} -gt 0 ]]; then
                add_issue "Missing pip packages: ${missing[*]}"
                return 1
            else
                success "Pip dependencies installed"
            fi
            ;;
    esac

    return 0
}

# =============================================================================
# Fix Functions
# =============================================================================

attempt_fixes() {
    local repo_root=$(get_repo_root)

    header "Attempting Fixes"

    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            *"not installed"*|*"not found"*)
                info "Attempting to install environment..."
                case "$ENV_TOOL" in
                    pixi)
                        if pixi install; then
                            success "Pixi environment installed"
                        else
                            fail "Could not install pixi environment"
                        fi
                        ;;
                    conda|mamba)
                        local conda_cmd="conda"
                        command -v mamba &>/dev/null && conda_cmd="mamba"
                        if [[ -f "$repo_root/environment.yml" ]]; then
                            if $conda_cmd env create -f "$repo_root/environment.yml" -y 2>/dev/null || \
                               $conda_cmd env update -f "$repo_root/environment.yml" --prune 2>/dev/null; then
                                success "Conda environment created/updated"
                            else
                                fail "Could not create conda environment"
                            fi
                        fi
                        ;;
                    venv)
                        if [[ ! -d "$repo_root/venv" ]]; then
                            python3 -m venv "$repo_root/venv"
                        fi
                        if [[ -f "$repo_root/requirements.txt" ]]; then
                            if "$repo_root/venv/bin/pip" install -r "$repo_root/requirements.txt"; then
                                success "Dependencies installed"
                            else
                                fail "Could not install dependencies"
                            fi
                        fi
                        ;;
                esac
                ;;

            *"Missing"*"packages"*)
                info "Installing missing packages..."
                case "$ENV_TOOL" in
                    pixi)
                        pixi install
                        ;;
                    conda|mamba)
                        local conda_cmd="conda"
                        command -v mamba &>/dev/null && conda_cmd="mamba"
                        if [[ -f "$repo_root/environment.yml" ]]; then
                            $conda_cmd env update -f "$repo_root/environment.yml" --prune
                        fi
                        ;;
                    venv)
                        local pip_cmd="${VIRTUAL_ENV:-$repo_root/venv}/bin/pip"
                        if [[ -f "$repo_root/requirements.txt" ]]; then
                            $pip_cmd install -r "$repo_root/requirements.txt"
                        fi
                        ;;
                esac
                ;;

            *"not activated"*)
                warn "Cannot auto-activate environment - please activate manually:"
                show_activation_help
                ;;
        esac
    done
}

show_activation_help() {
    local repo_root=$(get_repo_root)

    echo ""
    echo -e "${BOLD}To activate your environment:${NC}"

    case "$ENV_TOOL" in
        pixi)
            echo "  pixi shell"
            echo "  # Or run commands directly: pixi run python"
            ;;
        conda|mamba)
            echo "  conda activate $ENV_NAME"
            ;;
        venv)
            echo "  source $repo_root/venv/bin/activate  # Linux/macOS"
            echo "  $repo_root\\venv\\Scripts\\activate    # Windows"
            ;;
    esac
    echo ""
}

# =============================================================================
# Output Functions
# =============================================================================

determine_status() {
    if [[ ${#ISSUES[@]} -eq 0 ]]; then
        VALIDATION_STATUS="ACTIVE"
        return $EXIT_ACTIVE
    fi

    # Check for specific issue types
    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            *"not activated"*|*"not installed"*|*"not found"*)
                VALIDATION_STATUS="INACTIVE"
                return $EXIT_INACTIVE
                ;;
            *"version mismatch"*)
                VALIDATION_STATUS="MISMATCH"
                return $EXIT_MISMATCH
                ;;
            *"Missing"*)
                VALIDATION_STATUS="MISSING_DEPS"
                return $EXIT_MISSING_DEPS
                ;;
        esac
    done

    VALIDATION_STATUS="ERROR"
    return $EXIT_ERROR
}

output_json() {
    # Build JSON manually
    echo "{"
    echo "  \"status\": \"$VALIDATION_STATUS\","
    echo "  \"environment\": {"
    echo "    \"tool\": \"$ENV_TOOL\","
    echo "    \"name\": \"$ENV_NAME\","
    echo "    \"expected_python\": \"$EXPECTED_PYTHON\","
    echo "    \"actual_python\": \"${ACTUAL_PYTHON:-unknown}\""
    echo "  },"

    # Issues array
    echo "  \"issues\": ["
    local first=true
    for issue in "${ISSUES[@]}"; do
        [[ "$first" == "true" ]] || echo ","
        echo -n "    \"$issue\""
        first=false
    done
    echo ""
    echo "  ],"

    # Warnings array
    echo "  \"warnings\": ["
    first=true
    for warning in "${WARNINGS[@]}"; do
        [[ "$first" == "true" ]] || echo ","
        echo -n "    \"$warning\""
        first=false
    done
    echo ""
    echo "  ]"

    echo "}"
}

display_summary() {
    header "Validation Summary"

    # Status indicator
    case "$VALIDATION_STATUS" in
        ACTIVE)
            echo -e "${GREEN}${BOLD}STATUS: ACTIVE${NC} - Environment is valid and ready"
            ;;
        INACTIVE)
            echo -e "${YELLOW}${BOLD}STATUS: INACTIVE${NC} - Environment needs activation or setup"
            ;;
        MISMATCH)
            echo -e "${RED}${BOLD}STATUS: MISMATCH${NC} - Python version does not match specification"
            ;;
        MISSING_DEPS)
            echo -e "${YELLOW}${BOLD}STATUS: MISSING_DEPS${NC} - Some dependencies are not installed"
            ;;
        ERROR)
            echo -e "${RED}${BOLD}STATUS: ERROR${NC} - Configuration or validation error"
            ;;
    esac

    echo ""

    # Environment info
    echo -e "${BOLD}Environment:${NC}"
    echo "  Tool:     $ENV_TOOL"
    [[ -n "$ENV_NAME" ]] && echo "  Name:     $ENV_NAME"
    [[ -n "$EXPECTED_PYTHON" ]] && echo "  Python:   ${ACTUAL_PYTHON:-unknown} (expected $EXPECTED_PYTHON)"

    # Issues
    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}${BOLD}Issues:${NC}"
        for issue in "${ISSUES[@]}"; do
            echo -e "  ${RED}✗${NC} $issue"
        done
    fi

    # Warnings
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}${BOLD}Warnings:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}!${NC} $warning"
        done
    fi

    # Remediation suggestions
    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${BOLD}Suggested Actions:${NC}"

        for issue in "${ISSUES[@]}"; do
            case "$issue" in
                *"not activated"*)
                    show_activation_help
                    ;;
                *"not installed"*|*"not found"*)
                    case "$ENV_TOOL" in
                        pixi)
                            echo "  Run: pixi install"
                            ;;
                        conda|mamba)
                            echo "  Run: conda env create -f environment.yml"
                            ;;
                        venv)
                            echo "  Run: python3 -m venv venv && pip install -r requirements.txt"
                            ;;
                    esac
                    ;;
                *"Missing"*"packages"*)
                    case "$ENV_TOOL" in
                        pixi)
                            echo "  Run: pixi install"
                            ;;
                        conda|mamba)
                            echo "  Run: conda env update -f environment.yml --prune"
                            ;;
                        venv)
                            echo "  Run: pip install -r requirements.txt"
                            ;;
                    esac
                    ;;
                *"version mismatch"*)
                    echo "  Recreate environment with correct Python version"
                    echo "  Or update python_version in .env-config to match installed version"
                    ;;
            esac
        done
    fi
}

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << EOF
${BOLD}env-validate.sh${NC} - Python Environment Validation

${BOLD}USAGE${NC}
    ./env-validate.sh [OPTIONS]

${BOLD}OPTIONS${NC}
    --help, -h      Show this help message
    --json          Output validation result as JSON
    --quiet, -q     Quiet mode - exit code only (for CI)
    --fix           Attempt to fix detected issues
    --no-color      Disable colored output

${BOLD}EXIT CODES${NC}
    0  ACTIVE        Environment is valid and active
    1  ERROR         Configuration or script error
    2  INACTIVE      Environment not activated
    3  MISMATCH      Python version mismatch
    4  MISSING_DEPS  Missing dependencies

${BOLD}EXAMPLES${NC}
    # Full validation with report
    ./env-validate.sh

    # Get JSON for automation
    ./env-validate.sh --json

    # CI/script integration (uses exit code)
    ./env-validate.sh --quiet && echo "Environment OK"

    # Attempt automatic fixes
    ./env-validate.sh --fix

${BOLD}JSON OUTPUT${NC}
    {
      "status": "ACTIVE|INACTIVE|MISMATCH|MISSING_DEPS|ERROR",
      "environment": {
        "tool": "pixi|conda|venv",
        "name": "env-name",
        "expected_python": "3.11",
        "actual_python": "3.11"
      },
      "issues": ["..."],
      "warnings": ["..."]
    }

${BOLD}VALIDATION CHECKS${NC}
    1. Environment activation status
    2. Python version match
    3. Required dependencies installed
    4. Lock file currency (pixi)
EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                setup_colors
                show_help
                exit 0
                ;;
            --json)
                JSON_MODE=true
                shift
                ;;
            --quiet|-q)
                QUIET_MODE=true
                shift
                ;;
            --fix)
                FIX_MODE=true
                shift
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    setup_colors

    [[ "$JSON_MODE" != "true" ]] && [[ "$QUIET_MODE" != "true" ]] && header "Environment Validation"

    # Load configuration
    if ! load_config; then
        determine_status
        if [[ "$JSON_MODE" == "true" ]]; then
            output_json
        elif [[ "$QUIET_MODE" != "true" ]]; then
            display_summary
        fi
        exit $EXIT_ERROR
    fi

    # Run validation checks
    info "Tool: $ENV_TOOL"

    check_activation
    check_python_version
    check_dependencies

    # Determine overall status
    determine_status
    local exit_code=$?

    # Attempt fixes if requested
    if [[ "$FIX_MODE" == "true" ]] && [[ ${#ISSUES[@]} -gt 0 ]]; then
        attempt_fixes

        # Re-validate after fixes
        ISSUES=()
        WARNINGS=()
        check_activation
        check_python_version
        check_dependencies
        determine_status
        exit_code=$?
    fi

    # Output results
    if [[ "$JSON_MODE" == "true" ]]; then
        output_json
    elif [[ "$QUIET_MODE" != "true" ]]; then
        display_summary
    fi

    exit $exit_code
}

main "$@"
