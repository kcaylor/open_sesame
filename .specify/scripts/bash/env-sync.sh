#!/usr/bin/env bash
#
# env-sync.sh - Python Environment Dependency Synchronization Script
# Part of the res_spec Python Environment Management feature
#
# This script detects changes between installed packages and spec files,
# updates documentation, and maintains reproducibility.
#
# Usage:
#   ./env-sync.sh                    # Interactive mode - review and confirm changes
#   ./env-sync.sh --auto             # Automatic mode - sync without prompts
#   ./env-sync.sh --package numpy    # Document a specific package with annotation
#   ./env-sync.sh --json             # Output sync status as JSON
#   ./env-sync.sh --help             # Show usage information
#
# Supported environment tools:
#   - pixi   : Uses pixi.lock for dependency tracking
#   - conda  : Uses conda list for installed packages
#   - venv   : Uses pip freeze for installed packages
#

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Script state
AUTO_MODE=false
JSON_MODE=false
PACKAGE_MODE=false
EXPORT_METHODS_MODE=false
TARGET_PACKAGE=""
EXPORT_FORMAT=""
NO_COLOR=false

# Data structures (using temp files for portability)
INSTALLED_PACKAGES_FILE=""
SPEC_PACKAGES_FILE=""
NEW_PACKAGES_FILE=""
REMOVED_PACKAGES_FILE=""
CHANGED_PACKAGES_FILE=""

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

info() { [[ "$JSON_MODE" != "true" ]] && echo -e "${BLUE}[INFO]${NC} $*"; }
success() { [[ "$JSON_MODE" != "true" ]] && echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn() { [[ "$JSON_MODE" != "true" ]] && echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header() { [[ "$JSON_MODE" != "true" ]] && echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; }

# =============================================================================
# Cleanup
# =============================================================================

cleanup() {
    [[ -n "$INSTALLED_PACKAGES_FILE" ]] && rm -f "$INSTALLED_PACKAGES_FILE"
    [[ -n "$SPEC_PACKAGES_FILE" ]] && rm -f "$SPEC_PACKAGES_FILE"
    [[ -n "$NEW_PACKAGES_FILE" ]] && rm -f "$NEW_PACKAGES_FILE"
    [[ -n "$REMOVED_PACKAGES_FILE" ]] && rm -f "$REMOVED_PACKAGES_FILE"
    [[ -n "$CHANGED_PACKAGES_FILE" ]] && rm -f "$CHANGED_PACKAGES_FILE"
}

trap cleanup EXIT

# =============================================================================
# Configuration Loading
# =============================================================================

load_config() {
    local repo_root=$(get_repo_root)
    local config_file="$repo_root/.env-config"

    if [[ ! -f "$config_file" ]]; then
        error ".env-config not found!"
        echo "  Run 'env-init.sh' first to create environment configuration"
        exit 1
    fi

    # Parse config file
    ENV_TOOL=$(grep -E "^tool\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ' || echo "")
    ENV_NAME=$(grep -E "^env_name\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ' || echo "")

    if [[ -z "$ENV_TOOL" ]]; then
        error "Invalid .env-config - missing 'tool' field"
        exit 1
    fi

    info "Environment tool: $ENV_TOOL"
    [[ -n "$ENV_NAME" ]] && info "Environment name: $ENV_NAME"
}

# =============================================================================
# Package Detection Functions
# =============================================================================

# Normalize package name (lowercase, replace _ with -)
normalize_package_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-'
}

# Get installed packages for pip/venv
get_pip_packages() {
    local repo_root=$(get_repo_root)
    local pip_cmd=""

    # Find pip executable
    if [[ -f "$repo_root/venv/bin/pip" ]]; then
        pip_cmd="$repo_root/venv/bin/pip"
    elif command -v pip &>/dev/null; then
        pip_cmd="pip"
    else
        error "pip not found"
        return 1
    fi

    # Get installed packages (name==version format)
    $pip_cmd freeze 2>/dev/null | while read -r line; do
        # Handle both == and @ (for editable installs)
        if [[ "$line" =~ ^([^=@]+)==([^=]+)$ ]]; then
            local name=$(normalize_package_name "${BASH_REMATCH[1]}")
            local version="${BASH_REMATCH[2]}"
            echo "$name=$version"
        elif [[ "$line" =~ ^([^=@]+)@ ]]; then
            local name=$(normalize_package_name "${BASH_REMATCH[1]}")
            echo "$name=editable"
        fi
    done
}

# Get installed packages for conda
get_conda_packages() {
    local conda_cmd="conda"
    command -v mamba &>/dev/null && conda_cmd="mamba"

    # Get packages from conda list
    $conda_cmd list --export 2>/dev/null | grep -v "^#" | while read -r line; do
        if [[ "$line" =~ ^([^=]+)=([^=]+)= ]]; then
            local name=$(normalize_package_name "${BASH_REMATCH[1]}")
            local version="${BASH_REMATCH[2]}"
            echo "$name=$version"
        fi
    done
}

# Get installed packages for pixi
get_pixi_packages() {
    local repo_root=$(get_repo_root)

    # Check if pixi.lock exists
    if [[ ! -f "$repo_root/pixi.lock" ]]; then
        warn "pixi.lock not found - run 'pixi install' first"
        return 1
    fi

    # Parse pixi list output
    pixi list 2>/dev/null | tail -n +3 | while read -r name version rest; do
        if [[ -n "$name" ]] && [[ "$name" != "Package" ]]; then
            local normalized=$(normalize_package_name "$name")
            echo "$normalized=$version"
        fi
    done
}

# Get packages from requirements.txt
get_requirements_packages() {
    local repo_root=$(get_repo_root)
    local req_file="$repo_root/requirements.txt"

    if [[ ! -f "$req_file" ]]; then
        return 0
    fi

    grep -v "^#" "$req_file" | grep -v "^$" | while read -r line; do
        # Parse various requirement formats
        local name=""
        local version=""

        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)==([^ ]+) ]]; then
            name="${BASH_REMATCH[1]}"
            version="${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^([a-zA-Z0-9_-]+)\>=([^ ]+) ]]; then
            name="${BASH_REMATCH[1]}"
            version=">=${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^([a-zA-Z0-9_-]+)\~=([^ ]+) ]]; then
            name="${BASH_REMATCH[1]}"
            version="~=${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^([a-zA-Z0-9_-]+) ]]; then
            name="${BASH_REMATCH[1]}"
            version="any"
        fi

        if [[ -n "$name" ]]; then
            local normalized=$(normalize_package_name "$name")
            echo "$normalized=$version"
        fi
    done
}

# Get packages from environment.yml
get_conda_yml_packages() {
    local repo_root=$(get_repo_root)
    local yml_file="$repo_root/environment.yml"

    if [[ ! -f "$yml_file" ]]; then
        return 0
    fi

    # Simple YAML parsing for dependencies section
    local in_deps=false
    local in_pip=false

    while IFS= read -r line; do
        # Check if we're entering dependencies section
        if [[ "$line" =~ ^dependencies: ]]; then
            in_deps=true
            continue
        fi

        # Check if we're leaving dependencies (new top-level key)
        if [[ "$in_deps" == "true" ]] && [[ "$line" =~ ^[a-z] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
            in_deps=false
            continue
        fi

        # Skip if not in dependencies
        [[ "$in_deps" != "true" ]] && continue

        # Check for pip section
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*pip: ]]; then
            in_pip=true
            continue
        fi

        # Parse package line
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*([a-zA-Z0-9_-]+)([>=<~]+)?([0-9.]+)? ]]; then
            local name=$(normalize_package_name "${BASH_REMATCH[1]}")
            local op="${BASH_REMATCH[2]:-}"
            local version="${BASH_REMATCH[3]:-any}"

            # Skip pip marker
            [[ "$name" == "pip" ]] && continue

            if [[ -n "$op" ]]; then
                echo "$name=${op}${version}"
            else
                echo "$name=$version"
            fi
        fi
    done < "$yml_file"
}

# Get packages from pixi.toml
get_pixi_toml_packages() {
    local repo_root=$(get_repo_root)
    local toml_file="$repo_root/pixi.toml"

    if [[ ! -f "$toml_file" ]]; then
        return 0
    fi

    # Simple TOML parsing for [dependencies] section
    local in_deps=false

    while IFS= read -r line; do
        if [[ "$line" =~ ^\[dependencies\] ]]; then
            in_deps=true
            continue
        fi

        if [[ "$in_deps" == "true" ]] && [[ "$line" =~ ^\[ ]]; then
            in_deps=false
            continue
        fi

        [[ "$in_deps" != "true" ]] && continue

        # Parse package = "version" format
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
            local name=$(normalize_package_name "${BASH_REMATCH[1]}")
            local version="${BASH_REMATCH[2]}"
            echo "$name=$version"
        fi
    done < "$toml_file"
}

# =============================================================================
# Package Comparison
# =============================================================================

compare_packages() {
    # Create temp files
    INSTALLED_PACKAGES_FILE=$(mktemp)
    SPEC_PACKAGES_FILE=$(mktemp)
    NEW_PACKAGES_FILE=$(mktemp)
    REMOVED_PACKAGES_FILE=$(mktemp)
    CHANGED_PACKAGES_FILE=$(mktemp)

    # Get installed packages
    case "$ENV_TOOL" in
        pixi)
            get_pixi_packages > "$INSTALLED_PACKAGES_FILE"
            get_pixi_toml_packages > "$SPEC_PACKAGES_FILE"
            ;;
        conda|mamba)
            get_conda_packages > "$INSTALLED_PACKAGES_FILE"
            get_conda_yml_packages > "$SPEC_PACKAGES_FILE"
            ;;
        venv)
            get_pip_packages > "$INSTALLED_PACKAGES_FILE"
            get_requirements_packages > "$SPEC_PACKAGES_FILE"
            ;;
    esac

    # Find new packages (in installed but not in spec)
    while IFS='=' read -r name version; do
        [[ -z "$name" ]] && continue
        if ! grep -q "^$name=" "$SPEC_PACKAGES_FILE" 2>/dev/null; then
            echo "$name=$version" >> "$NEW_PACKAGES_FILE"
        fi
    done < "$INSTALLED_PACKAGES_FILE"

    # Find removed packages (in spec but not in installed)
    while IFS='=' read -r name version; do
        [[ -z "$name" ]] && continue
        if ! grep -q "^$name=" "$INSTALLED_PACKAGES_FILE" 2>/dev/null; then
            echo "$name=$version" >> "$REMOVED_PACKAGES_FILE"
        fi
    done < "$SPEC_PACKAGES_FILE"

    # Find version changes
    while IFS='=' read -r name installed_version; do
        [[ -z "$name" ]] && continue
        local spec_line=$(grep "^$name=" "$SPEC_PACKAGES_FILE" 2>/dev/null || echo "")
        if [[ -n "$spec_line" ]]; then
            local spec_version="${spec_line#*=}"
            # Skip if spec has a range (>=, ~=, etc.)
            if [[ ! "$spec_version" =~ ^[\>=\<\~] ]] && [[ "$installed_version" != "$spec_version" ]]; then
                echo "$name: $spec_version -> $installed_version" >> "$CHANGED_PACKAGES_FILE"
            fi
        fi
    done < "$INSTALLED_PACKAGES_FILE"
}

# =============================================================================
# Display Functions
# =============================================================================

display_changes() {
    local new_count=$(wc -l < "$NEW_PACKAGES_FILE" | tr -d ' ')
    local removed_count=$(wc -l < "$REMOVED_PACKAGES_FILE" | tr -d ' ')
    local changed_count=$(wc -l < "$CHANGED_PACKAGES_FILE" | tr -d ' ')

    header "Dependency Changes Detected"

    if [[ "$new_count" -gt 0 ]]; then
        echo -e "${GREEN}New packages ($new_count):${NC}"
        while IFS='=' read -r name version; do
            [[ -z "$name" ]] && continue
            echo -e "  ${GREEN}+${NC} $name ($version)"
        done < "$NEW_PACKAGES_FILE"
        echo ""
    fi

    if [[ "$removed_count" -gt 0 ]]; then
        echo -e "${RED}Removed packages ($removed_count):${NC}"
        while IFS='=' read -r name version; do
            [[ -z "$name" ]] && continue
            echo -e "  ${RED}-${NC} $name ($version)"
        done < "$REMOVED_PACKAGES_FILE"
        echo ""
    fi

    if [[ "$changed_count" -gt 0 ]]; then
        echo -e "${YELLOW}Version changes ($changed_count):${NC}"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            echo -e "  ${YELLOW}~${NC} $line"
        done < "$CHANGED_PACKAGES_FILE"
        echo ""
    fi

    if [[ "$new_count" -eq 0 ]] && [[ "$removed_count" -eq 0 ]] && [[ "$changed_count" -eq 0 ]]; then
        success "Environment is in sync - no changes detected"
        return 1
    fi

    return 0
}

# =============================================================================
# Sync Functions
# =============================================================================

update_spec_file() {
    local repo_root=$(get_repo_root)

    info "Updating specification files..."

    case "$ENV_TOOL" in
        pixi)
            # For pixi, we update pixi.toml
            # This is typically done with 'pixi add' so we just note the changes
            warn "For pixi, use 'pixi add <package>' to formally add dependencies"
            warn "Changes in pixi.lock will be tracked automatically"
            ;;
        conda|mamba)
            # Update environment.yml with new packages
            local yml_file="$repo_root/environment.yml"
            if [[ -f "$yml_file" ]]; then
                info "Run 'conda env export > environment.yml' to update"
            fi
            ;;
        venv)
            # Update requirements.txt
            local req_file="$repo_root/requirements.txt"
            info "Updating requirements.txt..."
            if [[ -f "$repo_root/venv/bin/pip" ]]; then
                "$repo_root/venv/bin/pip" freeze > "$req_file"
                success "requirements.txt updated"
            elif command -v pip &>/dev/null; then
                pip freeze > "$req_file"
                success "requirements.txt updated"
            fi
            ;;
    esac
}

update_env_config_packages() {
    local repo_root=$(get_repo_root)
    local config_file="$repo_root/.env-config"
    local date=$(date +%Y-%m-%d)

    info "Updating .env-config..."

    # Update last_sync timestamp
    if grep -q "^last_sync" "$config_file"; then
        sed -i.bak "s/^last_sync.*/last_sync = $date/" "$config_file"
        rm -f "$config_file.bak"
    fi

    # Add new packages to pending_packages for documentation
    local pending=""
    while IFS='=' read -r name version; do
        [[ -z "$name" ]] && continue
        pending="$pending $name"
    done < "$NEW_PACKAGES_FILE"

    if [[ -n "$pending" ]]; then
        if grep -q "^pending_packages" "$config_file"; then
            sed -i.bak "s/^pending_packages.*/pending_packages =$pending/" "$config_file"
            rm -f "$config_file.bak"
        fi
        info "Added${pending} to pending_packages for documentation"
    fi
}

# =============================================================================
# Package Documentation Mode
# =============================================================================

document_package() {
    local package="$1"
    local repo_root=$(get_repo_root)
    local config_file="$repo_root/.env-config"

    header "Document Package: $package"

    # Check if package exists
    local normalized=$(normalize_package_name "$package")

    echo "Package: $normalized"
    echo ""
    echo "Enter a description of how this package is used in your research."
    echo "This will be added to .env-config for manuscript documentation."
    echo ""
    read -p "Description: " description

    if [[ -z "$description" ]]; then
        warn "No description provided, skipping"
        return
    fi

    # Add to package_notes section in .env-config
    if grep -q "^\[package_notes\]" "$config_file"; then
        # Find the line after [package_notes] and add there
        local line_num=$(grep -n "^\[package_notes\]" "$config_file" | cut -d: -f1)
        local insert_line=$((line_num + 1))

        # Check if package already documented
        if grep -q "^$normalized\s*=" "$config_file"; then
            # Update existing entry
            sed -i.bak "s/^$normalized\s*=.*/$normalized = \"$description\"/" "$config_file"
            rm -f "$config_file.bak"
            success "Updated documentation for $normalized"
        else
            # Insert new entry after [package_notes]
            sed -i.bak "${insert_line}i\\
$normalized = \"$description\"
" "$config_file"
            rm -f "$config_file.bak"
            success "Added documentation for $normalized"
        fi
    else
        warn "Could not find [package_notes] section in .env-config"
    fi

    # Remove from pending_packages if present
    if grep -q "^pending_packages.*$normalized" "$config_file"; then
        sed -i.bak "s/ $normalized//" "$config_file"
        rm -f "$config_file.bak"
    fi
}

# =============================================================================
# JSON Output
# =============================================================================

output_json() {
    local new_count=$(wc -l < "$NEW_PACKAGES_FILE" | tr -d ' ')
    local removed_count=$(wc -l < "$REMOVED_PACKAGES_FILE" | tr -d ' ')
    local changed_count=$(wc -l < "$CHANGED_PACKAGES_FILE" | tr -d ' ')

    # Build JSON manually (no jq dependency)
    echo "{"
    echo "  \"status\": \"$([ $((new_count + removed_count + changed_count)) -eq 0 ] && echo "SYNCED" || echo "DRIFT_DETECTED")\","
    echo "  \"tool\": \"$ENV_TOOL\","
    echo "  \"env_name\": \"$ENV_NAME\","
    echo "  \"summary\": {"
    echo "    \"new_packages\": $new_count,"
    echo "    \"removed_packages\": $removed_count,"
    echo "    \"version_changes\": $changed_count"
    echo "  },"

    # New packages array
    echo "  \"new_packages\": ["
    local first=true
    while IFS='=' read -r name version; do
        [[ -z "$name" ]] && continue
        [[ "$first" == "true" ]] || echo ","
        echo -n "    {\"name\": \"$name\", \"version\": \"$version\"}"
        first=false
    done < "$NEW_PACKAGES_FILE"
    echo ""
    echo "  ],"

    # Removed packages array
    echo "  \"removed_packages\": ["
    first=true
    while IFS='=' read -r name version; do
        [[ -z "$name" ]] && continue
        [[ "$first" == "true" ]] || echo ","
        echo -n "    {\"name\": \"$name\", \"version\": \"$version\"}"
        first=false
    done < "$REMOVED_PACKAGES_FILE"
    echo ""
    echo "  ],"

    # Changed packages array
    echo "  \"version_changes\": ["
    first=true
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$first" == "true" ]] || echo ","
        echo -n "    \"$line\""
        first=false
    done < "$CHANGED_PACKAGES_FILE"
    echo ""
    echo "  ]"

    echo "}"
}

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << EOF
${BOLD}env-sync.sh${NC} - Python Environment Dependency Synchronization

${BOLD}USAGE${NC}
    ./env-sync.sh [OPTIONS]

${BOLD}OPTIONS${NC}
    --help, -h          Show this help message
    --auto              Automatic mode - sync without prompts
    --package PKG       Document a specific package with annotation
    --export-methods    Export package annotations as formatted methods paragraph
    --format FMT        Output format for --export-methods: paragraph (default), list, table
    --json              Output sync status as JSON (for agent integration)
    --no-color          Disable colored output

${BOLD}EXAMPLES${NC}
    # Check for dependency changes
    ./env-sync.sh

    # Automatic sync (update spec files)
    ./env-sync.sh --auto

    # Document a specific package
    ./env-sync.sh --package numpy

    # Export package annotations for manuscript methods section
    ./env-sync.sh --export-methods

    # Export as markdown table
    ./env-sync.sh --export-methods --format table

    # Get JSON status for CI/automation
    ./env-sync.sh --json

${BOLD}WORKFLOW${NC}
    1. Install new packages using your tool (pixi add, conda install, pip install)
    2. Run env-sync.sh to detect and document changes
    3. Use --package to add research documentation for new packages
    4. Commit updated spec files for reproducibility

${BOLD}OUTPUT${NC}
    The script detects:
    - New packages (installed but not in spec)
    - Removed packages (in spec but not installed)
    - Version changes (different versions between spec and installed)

${BOLD}JSON OUTPUT${NC}
    {
      "status": "SYNCED|DRIFT_DETECTED",
      "tool": "pixi|conda|venv",
      "summary": { "new_packages": N, "removed_packages": N, "version_changes": N },
      "new_packages": [{"name": "...", "version": "..."}],
      "removed_packages": [...],
      "version_changes": [...]
    }
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
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --json)
                JSON_MODE=true
                shift
                ;;
            --package)
                PACKAGE_MODE=true
                TARGET_PACKAGE="$2"
                shift 2
                ;;
            --export-methods)
                EXPORT_METHODS_MODE=true
                shift
                ;;
            --format)
                EXPORT_FORMAT="$2"
                shift 2
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

    # Export methods mode - call export-methods.sh and exit (T048-T049)
    if [[ "$EXPORT_METHODS_MODE" == "true" ]]; then
        local export_script="$SCRIPT_DIR/export-methods.sh"
        if [[ -f "$export_script" ]]; then
            local format_args=""
            if [[ -n "$EXPORT_FORMAT" ]]; then
                format_args="--format $EXPORT_FORMAT"
            fi
            if [[ "$NO_COLOR" == "true" ]]; then
                format_args="$format_args --no-color"
            fi
            exec "$export_script" $format_args
        else
            error "export-methods.sh not found at $export_script"
            exit 1
        fi
    fi

    # Load configuration
    load_config

    # Package documentation mode
    if [[ "$PACKAGE_MODE" == "true" ]]; then
        document_package "$TARGET_PACKAGE"
        exit 0
    fi

    # Compare packages
    header "Analyzing Dependencies"
    compare_packages

    # JSON output mode
    if [[ "$JSON_MODE" == "true" ]]; then
        output_json
        exit 0
    fi

    # Display changes
    if ! display_changes; then
        exit 0
    fi

    # Auto mode or prompt
    if [[ "$AUTO_MODE" == "true" ]]; then
        update_spec_file
        update_env_config_packages
        success "Sync complete"
    else
        echo ""
        read -p "Update specification files? [Y/n]: " confirm
        if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
            update_spec_file
            update_env_config_packages
            success "Sync complete"

            # Offer to document new packages
            if [[ -s "$NEW_PACKAGES_FILE" ]]; then
                echo ""
                read -p "Document new packages now? [y/N]: " doc_confirm
                if [[ "$doc_confirm" =~ ^[Yy]$ ]]; then
                    while IFS='=' read -r name version; do
                        [[ -z "$name" ]] && continue
                        document_package "$name"
                    done < "$NEW_PACKAGES_FILE"
                fi
            fi
        else
            info "Skipped - no changes made"
        fi
    fi
}

main "$@"
