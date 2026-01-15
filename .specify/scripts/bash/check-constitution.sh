#!/usr/bin/env bash
#
# check-constitution.sh - Constitution Compliance Check Script
# Part of the res_spec Speckit Research Integration feature (002)
#
# Validates plan.md against research constitution principles.
# Called by /speckit.plan command after plan generation.
#
# Usage:
#   ./check-constitution.sh <path-to-plan.md>         # Human-readable output
#   ./check-constitution.sh <path-to-plan.md> --json  # JSON output for agents
#   ./check-constitution.sh --help                    # Show usage
#
# Exit codes:
#   0 - Always (non-blocking - status conveyed in output)
#

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# =============================================================================
# Configuration
# =============================================================================

JSON_MODE=false
NO_COLOR=false
PLAN_FILE=""

# Check results
declare -a CHECKS=()
OVERALL_STATUS="PASS"

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

# =============================================================================
# Constitution Principle Check Functions (T007)
# =============================================================================

# Check 1: Research-First Development (Principle I)
check_research_context() {
    local plan_file="$1"
    local passed=true
    local message=""
    local suggestions=()

    # Look for research-oriented language in plan
    if grep -qiE 'research.*question|hypothesis|scientific.*objective|data.*analysis|manuscript|reproducib|publication|peer.*review' "$plan_file" 2>/dev/null; then
        message="Feature serves scientific research goals"
    elif grep -qiE 'research|analysis|data|scientific' "$plan_file" 2>/dev/null; then
        message="Research context present"
    else
        passed=false
        message="Missing research context"
        suggestions+=("Add research objective or scientific rationale for this feature")
        suggestions+=("Connect feature to broader research aims in Summary section")
    fi

    echo "research_first|$passed|$message|$(IFS='|'; echo "${suggestions[*]:-}")"
}

# Check 2: Reproducibility & Transparency (Principle II)
check_validation_strategy() {
    local plan_file="$1"
    local passed=true
    local message=""
    local suggestions=()

    # Search for validation-related keywords
    if grep -qiE 'validation.*strategy|test.*data|benchmark|known.*result|ground.*truth|unit.*test|integration.*test' "$plan_file" 2>/dev/null; then
        message="Validation strategy documented in plan"
    elif grep -qiE 'validation|test|verify|check' "$plan_file" 2>/dev/null; then
        message="Validation approach mentioned"
    else
        passed=false
        message="Missing validation strategy"
        suggestions+=("Add 'Validation Strategy' section to plan")
        suggestions+=("Specify test data or benchmarks for validating implementation")
        suggestions+=("Document how implementation will be tested against known results")
    fi

    echo "reproducibility|$passed|$message|$(IFS='|'; echo "${suggestions[*]:-}")"
}

# Check 3: Documentation as Science Communication (Principle III)
check_method_references() {
    local plan_file="$1"
    local passed=true
    local message=""
    local suggestions=()

    # Check if implementing known statistical/computational methods
    local implements_known_method=false
    if grep -qiE 'implement.*(regression|clustering|kriging|ANOVA|t-test|correlation|PCA|interpolation|autocorrelation|spectral|fourier|wavelet)' "$plan_file" 2>/dev/null; then
        implements_known_method=true
    fi

    # Look for citation patterns: "Author et al. YEAR" or "Author (YEAR)" or DOI
    local has_references=false
    if grep -qE '[A-Z][a-z]+\s+(et\s+al\.\s+)?(\([0-9]{4}\)|[0-9]{4})|DOI:|arXiv:|doi\.org' "$plan_file" 2>/dev/null; then
        has_references=true
    fi

    if [[ "$implements_known_method" == "true" ]] && [[ "$has_references" == "false" ]]; then
        passed=false
        message="Implementing published method without citation"
        suggestions+=("Add references to papers or documentation for methods being implemented")
        suggestions+=("Format: Author et al. (YEAR) or include DOI")
    elif [[ "$has_references" == "true" ]]; then
        message="Method references included"
    else
        message="No published methods detected (references not required)"
    fi

    echo "documentation|$passed|$message|$(IFS='|'; echo "${suggestions[*]:-}")"
}

# Check 4: Incremental Implementation with Validation (Principle IV)
check_incremental_validation() {
    local plan_file="$1"
    local passed=true
    local message=""
    local suggestions=()

    # Look for MVP marker and priority labels
    local has_mvp=false
    local has_priorities=false

    if grep -qiE 'MVP|minimum.*viable|🎯.*MVP|P1.*MVP' "$plan_file" 2>/dev/null; then
        has_mvp=true
    fi

    if grep -qE '\(P[0-9]\)|Priority:\s*P[0-9]|\[P[0-9]\]' "$plan_file" 2>/dev/null; then
        has_priorities=true
    fi

    if [[ "$has_mvp" == "true" ]] || [[ "$has_priorities" == "true" ]]; then
        message="MVP defined with prioritized user stories"
    elif grep -qiE 'phase|step|stage|increment' "$plan_file" 2>/dev/null; then
        message="Incremental approach present"
    else
        passed=false
        message="Plan may lack incremental delivery strategy"
        suggestions+=("Mark MVP or P1 priority on critical user stories")
        suggestions+=("Ensure each user story is independently testable")
    fi

    echo "incremental_validation|$passed|$message|$(IFS='|'; echo "${suggestions[*]:-}")"
}

# Check 5: Library & Method Integration (Principle V)
check_custom_implementation_justification() {
    local plan_file="$1"
    local passed=true
    local message=""
    local suggestions=()

    # Check for custom implementation keywords
    local has_custom=false
    if grep -qiE 'custom|from.*scratch|build.*own|implement.*ourselves|write.*own' "$plan_file" 2>/dev/null; then
        has_custom=true
    fi

    # Check for justification nearby
    local has_justification=false
    if [[ "$has_custom" == "true" ]]; then
        if grep -qiE 'because|rationale|reason|justif|due.*to|requirement|constraint' "$plan_file" 2>/dev/null; then
            has_justification=true
        fi
    fi

    # Check if using standard libraries
    local uses_libraries=false
    if grep -qiE 'numpy|pandas|scikit|scipy|matplotlib|pytorch|tensorflow|pysal|geopandas|rasterio|xarray' "$plan_file" 2>/dev/null; then
        uses_libraries=true
    fi

    if [[ "$has_custom" == "true" ]] && [[ "$has_justification" == "false" ]]; then
        passed=false
        message="Custom implementation without justification"
        suggestions+=("Fill Complexity Tracking table explaining why standard libraries are insufficient")
        suggestions+=("Document rationale for custom implementation vs library usage")
    elif [[ "$uses_libraries" == "true" ]]; then
        message="Uses existing libraries appropriately"
    else
        message="Custom implementations justified or using standard approaches"
    fi

    echo "library_integration|$passed|$message|$(IFS='|'; echo "${suggestions[*]:-}")"
}

# =============================================================================
# Main Check Runner
# =============================================================================

run_all_checks() {
    local plan_file="$1"

    # Run all 5 principle checks
    local result

    result=$(check_research_context "$plan_file")
    CHECKS+=("$result")

    result=$(check_validation_strategy "$plan_file")
    CHECKS+=("$result")

    result=$(check_method_references "$plan_file")
    CHECKS+=("$result")

    result=$(check_incremental_validation "$plan_file")
    CHECKS+=("$result")

    result=$(check_custom_implementation_justification "$plan_file")
    CHECKS+=("$result")

    # Determine overall status
    local fail_count=0
    for check in "${CHECKS[@]}"; do
        local passed=$(echo "$check" | cut -d'|' -f2)
        if [[ "$passed" == "false" ]]; then
            ((fail_count++))
        fi
    done

    if [[ $fail_count -eq 0 ]]; then
        OVERALL_STATUS="PASS"
    elif [[ $fail_count -lt 3 ]]; then
        OVERALL_STATUS="WARN"
    else
        OVERALL_STATUS="FAIL"
    fi
}

# =============================================================================
# Output Functions (T009)
# =============================================================================

output_json() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "{"
    echo "  \"status\": \"$OVERALL_STATUS\","
    echo "  \"principle_checks\": {"

    local first=true
    for check in "${CHECKS[@]}"; do
        local principle=$(echo "$check" | cut -d'|' -f1)
        local passed=$(echo "$check" | cut -d'|' -f2)
        local message=$(echo "$check" | cut -d'|' -f3)
        local suggestions_str=$(echo "$check" | cut -d'|' -f4-)

        [[ "$first" == "true" ]] || echo ","
        first=false

        echo -n "    \"$principle\": {"
        echo -n "\"passed\": $passed, "
        echo -n "\"message\": \"$message\", "
        echo -n "\"suggestions\": ["

        if [[ -n "$suggestions_str" ]]; then
            local sfirst=true
            IFS='|' read -ra SUGG <<< "$suggestions_str"
            for s in "${SUGG[@]}"; do
                [[ -z "$s" ]] && continue
                [[ "$sfirst" == "true" ]] || echo -n ", "
                sfirst=false
                echo -n "\"$s\""
            done
        fi

        echo -n "]}"
    done

    echo ""
    echo "  },"

    # Flagged sections
    echo "  \"flagged_sections\": ["
    local ffirst=true
    for check in "${CHECKS[@]}"; do
        local passed=$(echo "$check" | cut -d'|' -f2)
        if [[ "$passed" == "false" ]]; then
            local principle=$(echo "$check" | cut -d'|' -f1)
            local message=$(echo "$check" | cut -d'|' -f3)

            [[ "$ffirst" == "true" ]] || echo ","
            ffirst=false

            local issue_type="unknown"
            case "$principle" in
                reproducibility) issue_type="missing_validation_strategy" ;;
                documentation) issue_type="missing_method_refs" ;;
                library_integration) issue_type="unjustified_custom_impl" ;;
                research_first) issue_type="missing_research_context" ;;
                incremental_validation) issue_type="missing_mvp_strategy" ;;
            esac

            echo -n "    {\"section_name\": \"$principle\", \"issue_type\": \"$issue_type\", \"recommendation\": \"$message\"}"
        fi
    done
    echo ""
    echo "  ],"

    echo "  \"bypass_acknowledged\": false,"
    echo "  \"timestamp\": \"$timestamp\""
    echo "}"
}

output_human() {
    echo ""
    echo -e "${BOLD}${CYAN}Constitution Compliance Check${NC}"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    local fail_count=0

    for check in "${CHECKS[@]}"; do
        local principle=$(echo "$check" | cut -d'|' -f1)
        local passed=$(echo "$check" | cut -d'|' -f2)
        local message=$(echo "$check" | cut -d'|' -f3)
        local suggestions_str=$(echo "$check" | cut -d'|' -f4-)

        # Format principle name
        local display_name=""
        case "$principle" in
            research_first) display_name="Research-First Development" ;;
            reproducibility) display_name="Reproducibility & Transparency" ;;
            documentation) display_name="Documentation as Science Communication" ;;
            incremental_validation) display_name="Incremental Implementation with Validation" ;;
            library_integration) display_name="Library & Method Integration" ;;
            *) display_name="$principle" ;;
        esac

        if [[ "$passed" == "true" ]]; then
            echo -e "${GREEN}✅${NC} ${BOLD}$display_name${NC}: PASS"
            echo -e "   ${DIM}$message${NC}"
        else
            ((fail_count++))
            echo -e "${YELLOW}⚠️${NC}  ${BOLD}$display_name${NC}: WARN"
            echo -e "   ${YELLOW}$message${NC}"

            if [[ -n "$suggestions_str" ]]; then
                echo ""
                echo -e "   ${BOLD}Recommendations:${NC}"
                IFS='|' read -ra SUGG <<< "$suggestions_str"
                for s in "${SUGG[@]}"; do
                    [[ -z "$s" ]] && continue
                    echo -e "   • $s"
                done
            fi
        fi
        echo ""
    done

    echo "═══════════════════════════════════════════════════════════"

    if [[ "$OVERALL_STATUS" == "PASS" ]]; then
        echo -e "${GREEN}${BOLD}Overall Status: PASS${NC}"
        echo ""
        echo "All constitution principles aligned. Ready to proceed."
    elif [[ "$OVERALL_STATUS" == "WARN" ]]; then
        echo -e "${YELLOW}${BOLD}Overall Status: WARN ($fail_count concerns)${NC}"
        echo ""
        echo "Would you like to fix these issues or proceed anyway?"
        echo ""
        echo -e "Options:"
        echo -e "  1. ${GREEN}Fix now${NC} (recommended) - Update plan.md to address concerns"
        echo -e "  2. ${YELLOW}Proceed without fixing${NC} - Type: \"proceed without fix\""
    else
        echo -e "${RED}${BOLD}Overall Status: FAIL ($fail_count concerns)${NC}"
        echo ""
        echo "Multiple constitution principles not met."
        echo "Please address the recommendations above before proceeding."
    fi

    echo ""
}

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << EOF
${BOLD}check-constitution.sh${NC} - Constitution Compliance Check

${BOLD}USAGE${NC}
    ./check-constitution.sh <path-to-plan.md> [OPTIONS]

${BOLD}OPTIONS${NC}
    --json          Output as JSON (for agent integration)
    --no-color      Disable colored output
    --help, -h      Show this help message

${BOLD}DESCRIPTION${NC}
    Validates a plan.md file against the 5 constitution principles:
    1. Research-First Development - Feature serves scientific goals
    2. Reproducibility & Transparency - Validation strategy documented
    3. Documentation as Science Communication - Method references included
    4. Incremental Implementation - MVP defined with priorities
    5. Library & Method Integration - Standard libraries used or custom justified

${BOLD}EXIT CODES${NC}
    0 - Always (non-blocking - status conveyed in output)

${BOLD}OUTPUT${NC}
    PASS - All principles aligned
    WARN - Some concerns (1-2 principles)
    FAIL - Multiple concerns (3+ principles)

${BOLD}EXAMPLES${NC}
    # Human-readable check
    ./check-constitution.sh ./specs/003-analysis/plan.md

    # JSON output for agents
    ./check-constitution.sh ./specs/003-analysis/plan.md --json

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
            --no-color)
                NO_COLOR=true
                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 0  # Non-blocking
                ;;
            *)
                if [[ -z "$PLAN_FILE" ]]; then
                    PLAN_FILE="$1"
                fi
                shift
                ;;
        esac
    done

    setup_colors

    # Validate plan file
    if [[ -z "$PLAN_FILE" ]]; then
        echo "Error: No plan file specified" >&2
        echo "Usage: ./check-constitution.sh <path-to-plan.md> [--json]" >&2
        exit 0  # Non-blocking
    fi

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "Error: Plan file not found: $PLAN_FILE" >&2
        exit 0  # Non-blocking
    fi

    # Verify constitution.md exists
    local repo_root=$(get_repo_root)
    local constitution_file="$repo_root/.specify/memory/constitution.md"
    if [[ ! -f "$constitution_file" ]]; then
        echo "Warning: constitution.md not found at $constitution_file" >&2
        echo "Constitution check will use default principle patterns" >&2
    fi

    # Run checks
    run_all_checks "$PLAN_FILE"

    # Output results
    if [[ "$JSON_MODE" == "true" ]]; then
        output_json
    else
        output_human
    fi

    # Always exit 0 (non-blocking)
    exit 0
}

main "$@"
