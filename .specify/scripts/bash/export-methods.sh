#!/usr/bin/env bash
#
# export-methods.sh - Package Annotation Export Script
# Part of the res_spec Speckit Research Integration feature (002)
#
# Exports package annotations from .env-config as formatted methods paragraph
# for inclusion in manuscript methods sections.
#
# Usage:
#   ./export-methods.sh                    # Default paragraph format
#   ./export-methods.sh --format paragraph # Prose paragraph
#   ./export-methods.sh --format list      # Bulleted list
#   ./export-methods.sh --format table     # Markdown table
#   ./export-methods.sh --help             # Show usage
#
# Exit codes:
#   0 - Success - formatted output generated
#   1 - Error - .env-config missing or malformed
#   2 - Warning - no package annotations found
#

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# =============================================================================
# Configuration
# =============================================================================

OUTPUT_FORMAT="paragraph"
NO_COLOR=false

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
# Clipboard Functions (T008 - Cross-platform clipboard detection)
# =============================================================================

copy_to_clipboard() {
    local content="$1"

    # Try clipboard tools in order of preference
    if command -v pbcopy &>/dev/null; then
        # macOS
        echo -n "$content" | pbcopy
        echo -e "${GREEN}✅${NC} Copied to clipboard (pbcopy)"
        return 0
    elif command -v xclip &>/dev/null; then
        # Linux with xclip
        echo -n "$content" | xclip -selection clipboard
        echo -e "${GREEN}✅${NC} Copied to clipboard (xclip)"
        return 0
    elif command -v xsel &>/dev/null; then
        # Linux with xsel
        echo -n "$content" | xsel --clipboard --input
        echo -e "${GREEN}✅${NC} Copied to clipboard (xsel)"
        return 0
    elif command -v clip.exe &>/dev/null; then
        # Windows/WSL
        echo -n "$content" | clip.exe
        echo -e "${GREEN}✅${NC} Copied to clipboard (clip.exe)"
        return 0
    else
        # No clipboard tool available (T011 - graceful fallback)
        echo -e "${YELLOW}⚠️${NC}  Clipboard not available - output displayed below"
        echo -e "${DIM}   (Install xclip on Linux or use macOS/Windows)${NC}"
        return 1
    fi
}

# =============================================================================
# Package Notes Parsing
# =============================================================================

# Parse package_notes section from .env-config
# Returns: tab-separated lines of package_name, version, reason, reference
parse_package_notes() {
    local config_file="$1"
    local in_package_notes=false
    local current_package=""
    local current_version=""
    local current_reason=""
    local current_reference=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check for package_notes section start
        if [[ "$line" =~ ^package_notes: ]]; then
            in_package_notes=true
            continue
        fi

        # Check for end of package_notes (new top-level key)
        if [[ "$in_package_notes" == "true" ]] && [[ "$line" =~ ^[a-z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
            # Output last package if any
            if [[ -n "$current_package" ]]; then
                echo -e "${current_package}\t${current_version}\t${current_reason}\t${current_reference}"
            fi
            in_package_notes=false
            continue
        fi

        # Skip if not in package_notes
        [[ "$in_package_notes" != "true" ]] && continue

        # Parse YAML list items
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*package_name:[[:space:]]*\"?([^\"]+)\"? ]]; then
            # Output previous package if exists
            if [[ -n "$current_package" ]]; then
                echo -e "${current_package}\t${current_version}\t${current_reason}\t${current_reference}"
            fi
            current_package="${BASH_REMATCH[1]}"
            current_version=""
            current_reason=""
            current_reference=""
        elif [[ "$line" =~ ^[[:space:]]+package_name:[[:space:]]*\"?([^\"]+)\"? ]]; then
            # Output previous package if exists
            if [[ -n "$current_package" ]]; then
                echo -e "${current_package}\t${current_version}\t${current_reason}\t${current_reference}"
            fi
            current_package="${BASH_REMATCH[1]}"
            current_version=""
            current_reason=""
            current_reference=""
        elif [[ "$line" =~ ^[[:space:]]+version:[[:space:]]*\"?([^\"]+)\"? ]]; then
            current_version="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]+reason_added:[[:space:]]*\"?([^\"]+)\"? ]]; then
            current_reason="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]+reference:[[:space:]]*\"?([^\"]+)\"? ]]; then
            current_reference="${BASH_REMATCH[1]}"
        fi
    done < "$config_file"

    # Output last package if any
    if [[ -n "$current_package" ]]; then
        echo -e "${current_package}\t${current_version}\t${current_reason}\t${current_reference}"
    fi
}

# =============================================================================
# Formatting Functions (T010 - paragraph/list/table format support)
# =============================================================================

# Generate paragraph format
format_paragraph() {
    local packages=()
    while IFS=$'\t' read -r name version reason reference; do
        [[ -z "$name" ]] && continue

        local part="$name"
        [[ -n "$version" ]] && part="$part $version"
        [[ -n "$reason" ]] && part="$part for $reason"
        if [[ -n "$reference" ]]; then
            part="$part ($reference)"
        fi
        packages+=("$part")
    done

    # Join packages with proper grammar
    local count=${#packages[@]}
    local result=""

    if [[ $count -eq 0 ]]; then
        return
    elif [[ $count -eq 1 ]]; then
        result="${packages[0]}"
    elif [[ $count -eq 2 ]]; then
        result="${packages[0]} and ${packages[1]}"
    else
        local last_idx=$((count - 1))
        for ((i=0; i<last_idx; i++)); do
            result="$result${packages[$i]}, "
        done
        result="${result}and ${packages[$last_idx]}"
    fi

    echo "Software packages used in this analysis include: ${result}."
}

# Generate list format
format_list() {
    echo "Software packages used:"
    echo ""
    while IFS=$'\t' read -r name version reason reference; do
        [[ -z "$name" ]] && continue

        local line="- $name"
        [[ -n "$version" ]] && line="$line $version"
        [[ -n "$reason" ]] && line="$line: $reason"
        if [[ -n "$reference" ]]; then
            line="$line ($reference)"
        fi
        echo "$line"
    done
}

# Generate table format
format_table() {
    echo "| Package | Version | Purpose | Reference |"
    echo "|---------|---------|---------|-----------|"
    while IFS=$'\t' read -r name version reason reference; do
        [[ -z "$name" ]] && continue
        echo "| $name | ${version:-N/A} | ${reason:-N/A} | ${reference:-N/A} |"
    done
}

# =============================================================================
# Main Export Function
# =============================================================================

export_methods() {
    local repo_root=$(get_repo_root)
    local config_file="$repo_root/.env-config"

    # Check if .env-config exists
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}Error:${NC} .env-config not found at $config_file" >&2
        echo "" >&2
        echo "Initialize environment with:" >&2
        echo "  env-init.sh" >&2
        exit 1
    fi

    # Parse package notes
    local notes
    notes=$(parse_package_notes "$config_file")

    # Check if any packages found (T058 - handle empty gracefully)
    if [[ -z "$notes" ]]; then
        echo -e "${YELLOW}⚠️${NC}  No package annotations found in .env-config" >&2
        echo "" >&2
        echo "Add annotations with:" >&2
        echo "  env-sync.sh --package <package-name>" >&2
        exit 2
    fi

    # Format output based on selected format
    local formatted_output
    case "$OUTPUT_FORMAT" in
        paragraph)
            formatted_output=$(echo "$notes" | format_paragraph)
            ;;
        list)
            formatted_output=$(echo "$notes" | format_list)
            ;;
        table)
            formatted_output=$(echo "$notes" | format_table)
            ;;
        *)
            echo "Unknown format: $OUTPUT_FORMAT" >&2
            exit 1
            ;;
    esac

    # Try to copy to clipboard
    echo ""
    copy_to_clipboard "$formatted_output" || true

    # Display output
    echo ""
    echo -e "Methods $OUTPUT_FORMAT ($OUTPUT_FORMAT format):"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "$formatted_output"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Paste this into your manuscript methods section."
    echo ""
}

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << EOF
${BOLD}export-methods.sh${NC} - Package Annotation Export

${BOLD}USAGE${NC}
    ./export-methods.sh [OPTIONS]

${BOLD}OPTIONS${NC}
    --format FORMAT     Output format: paragraph (default), list, table
    --no-color          Disable colored output
    --help, -h          Show this help message

${BOLD}DESCRIPTION${NC}
    Reads package annotations from .env-config and generates formatted
    output suitable for inclusion in manuscript methods sections.

    Annotations are stored when packages are installed using:
        env-sync.sh --package <package-name>

${BOLD}OUTPUT FORMATS${NC}
    paragraph   Prose paragraph for methods section (default)
                "Software packages used include: numpy 1.24 for..."

    list        Bulleted list format
                - numpy 1.24: Array processing (Harris et al. 2020)

    table       Markdown table for supplementary materials
                | Package | Version | Purpose | Reference |

${BOLD}CLIPBOARD${NC}
    Output is automatically copied to clipboard if available:
    - macOS: pbcopy
    - Linux: xclip or xsel
    - Windows/WSL: clip.exe

    Falls back to terminal-only output if clipboard unavailable.

${BOLD}EXIT CODES${NC}
    0 - Success - formatted output generated
    1 - Error - .env-config missing or malformed
    2 - Warning - no package annotations found

${BOLD}EXAMPLES${NC}
    # Default paragraph format
    ./export-methods.sh

    # Bulleted list
    ./export-methods.sh --format list

    # Markdown table
    ./export-methods.sh --format table

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
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
        esac
    done

    setup_colors

    # Validate format
    case "$OUTPUT_FORMAT" in
        paragraph|list|table)
            ;;
        *)
            echo "Error: Unknown format '$OUTPUT_FORMAT'" >&2
            echo "Valid formats: paragraph, list, table" >&2
            exit 1
            ;;
    esac

    # Run export
    export_methods
}

main "$@"
