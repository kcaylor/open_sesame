#!/usr/bin/env bash
#
# env-init.sh - Python Environment Initialization Script
# Part of the res_spec Python Environment Management feature
#
# This script provides guided environment setup with educational prompts,
# auto-detection of available tools, and support for reproducible environments.
#
# Usage:
#   ./env-init.sh                    # Interactive mode with prompts
#   ./env-init.sh --from-config      # Reproduce environment from .env-config
#   ./env-init.sh --tool pixi        # Skip tool selection, use pixi
#   ./env-init.sh --quiet            # Non-interactive mode (uses defaults)
#   ./env-init.sh --help             # Show usage information
#
# Supported environment tools:
#   - pixi   : Modern, fast package manager (recommended for geospatial)
#   - conda  : Traditional conda/mamba environments
#   - venv   : Python's built-in virtual environments
#

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Default values
DEFAULT_PYTHON_VERSION="3.11"
DEFAULT_ENV_NAME="res-spec"

# Script state
QUIET_MODE=false
FROM_CONFIG=false
SELECTED_TOOL=""
PYTHON_VERSION=""
ENV_NAME=""
NO_COLOR=false

# =============================================================================
# Color and Output Functions
# =============================================================================

# Check if terminal supports colors
supports_color() {
    if [[ "$NO_COLOR" == "true" ]] || [[ -n "${NO_COLOR:-}" ]]; then
        return 1
    fi
    if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
        return 0
    fi
    return 1
}

# Color codes (set based on terminal support)
setup_colors() {
    if supports_color; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m' # No Color
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        MAGENTA=''
        CYAN=''
        BOLD=''
        DIM=''
        NC=''
    fi
}

# Output functions
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header() { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; }

# Progress indicator
progress() {
    local msg="$1"
    echo -ne "${DIM}>>> ${msg}...${NC}"
}

progress_done() {
    echo -e " ${GREEN}done${NC}"
}

progress_fail() {
    echo -e " ${RED}failed${NC}"
}

# =============================================================================
# Platform Detection
# =============================================================================

detect_platform() {
    local os=""
    local arch=""

    case "$(uname -s)" in
        Linux*)     os="linux";;
        Darwin*)    os="macos";;
        MINGW*|MSYS*|CYGWIN*) os="windows";;
        *)          os="unknown";;
    esac

    case "$(uname -m)" in
        x86_64|amd64)   arch="x64";;
        arm64|aarch64)  arch="arm64";;
        *)              arch="$(uname -m)";;
    esac

    echo "${os}-${arch}"
}

# =============================================================================
# Tool Detection
# =============================================================================

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Detect available environment tools
detect_tools() {
    local available=()

    if command_exists pixi; then
        available+=("pixi")
    fi

    if command_exists mamba; then
        available+=("mamba")
    elif command_exists conda; then
        available+=("conda")
    fi

    if command_exists python3 && python3 -c "import venv" &>/dev/null; then
        available+=("venv")
    elif command_exists python && python -c "import venv" &>/dev/null; then
        available+=("venv")
    fi

    echo "${available[@]}"
}

# Get version of a tool
get_tool_version() {
    local tool="$1"
    case "$tool" in
        pixi)
            pixi --version 2>/dev/null | head -1 || echo "unknown"
            ;;
        conda|mamba)
            "$tool" --version 2>/dev/null | head -1 || echo "unknown"
            ;;
        venv)
            python3 --version 2>/dev/null || python --version 2>/dev/null || echo "unknown"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# =============================================================================
# Educational Prompts
# =============================================================================

show_tool_comparison() {
    header "Choosing a Python Environment Tool"

    echo -e "${BOLD}Available tools on your system:${NC}"
    echo ""

    local tools=($(detect_tools))

    if [[ ${#tools[@]} -eq 0 ]]; then
        error "No environment tools detected!"
        echo ""
        echo "Please install one of the following:"
        echo "  - pixi: https://prefix.dev/docs/pixi/overview"
        echo "  - conda: https://docs.conda.io/en/latest/miniconda.html"
        echo "  - Python with venv: https://www.python.org/downloads/"
        exit 1
    fi

    for tool in "${tools[@]}"; do
        local version=$(get_tool_version "$tool")
        echo -e "  ${GREEN}✓${NC} ${BOLD}$tool${NC} ($version)"
    done
    echo ""

    echo -e "${BOLD}Tool Comparison:${NC}"
    echo ""
    echo -e "${CYAN}PIXI${NC} (Recommended for geospatial research)"
    echo "  ✓ Fast installation (Rust-based, parallel downloads)"
    echo "  ✓ Excellent for complex dependencies (GDAL, PROJ, etc.)"
    echo "  ✓ Project-local environments (no activation needed)"
    echo "  ✓ Cross-platform lockfiles for reproducibility"
    echo "  ✗ Newer tool, smaller community"
    echo ""
    echo -e "${CYAN}CONDA/MAMBA${NC} (Traditional choice)"
    echo "  ✓ Mature ecosystem, large community"
    echo "  ✓ Good for geospatial packages via conda-forge"
    echo "  ✓ Supports non-Python dependencies"
    echo "  ✗ Slower than pixi"
    echo "  ✗ Environment activation required"
    echo ""
    echo -e "${CYAN}VENV${NC} (Python built-in)"
    echo "  ✓ No additional installation needed"
    echo "  ✓ Simple and lightweight"
    echo "  ✗ Python-only packages (pip)"
    echo "  ✗ Geospatial packages can be difficult to install"
    echo "  ✗ Platform-specific issues with binary packages"
    echo ""
}

# =============================================================================
# User Input Functions
# =============================================================================

prompt_tool_selection() {
    local tools=($(detect_tools))

    if [[ ${#tools[@]} -eq 1 ]]; then
        SELECTED_TOOL="${tools[0]}"
        info "Only one tool available, using: $SELECTED_TOOL"
        return
    fi

    echo -e "${BOLD}Select your environment tool:${NC}"
    local i=1
    for tool in "${tools[@]}"; do
        echo "  $i) $tool"
        ((i++))
    done
    echo ""

    while true; do
        read -p "Enter choice (1-${#tools[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#tools[@]} ]]; then
            SELECTED_TOOL="${tools[$((choice-1))]}"
            break
        else
            warn "Invalid choice. Please enter a number between 1 and ${#tools[@]}"
        fi
    done

    success "Selected: $SELECTED_TOOL"
}

prompt_python_version() {
    echo ""
    echo -e "${BOLD}Python Version${NC}"
    echo "  Recommended: 3.11 (stable, good package support)"
    echo "  Also supported: 3.10, 3.12"
    echo ""

    read -p "Enter Python version [$DEFAULT_PYTHON_VERSION]: " version
    PYTHON_VERSION="${version:-$DEFAULT_PYTHON_VERSION}"

    # Validate format
    if [[ ! "$PYTHON_VERSION" =~ ^3\.[0-9]+$ ]]; then
        warn "Unusual version format. Expected format: 3.XX"
    fi

    success "Python version: $PYTHON_VERSION"
}

prompt_env_name() {
    echo ""
    local default_name=$(basename "$(pwd)")
    default_name="${default_name:-$DEFAULT_ENV_NAME}"

    read -p "Environment name [$default_name]: " name
    ENV_NAME="${name:-$default_name}"

    # Sanitize name (remove spaces, special chars)
    ENV_NAME=$(echo "$ENV_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-_')

    success "Environment name: $ENV_NAME"
}

# =============================================================================
# Python Version Validation
# =============================================================================

validate_python_version() {
    local tool="$1"
    local version="$2"

    progress "Checking Python $version availability"

    case "$tool" in
        pixi)
            # Pixi can install any Python version from conda-forge
            progress_done
            return 0
            ;;
        conda|mamba)
            # Check if conda can find the Python version
            if "$tool" search "python=$version" &>/dev/null; then
                progress_done
                return 0
            else
                progress_fail
                warn "Python $version may not be available in conda channels"
                return 1
            fi
            ;;
        venv)
            # Check if system Python matches requested version
            local sys_version
            sys_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "")
            if [[ "$sys_version" == "$version" ]]; then
                progress_done
                return 0
            else
                progress_fail
                warn "System Python is $sys_version, requested $version"
                echo "  venv will use system Python ($sys_version)"
                PYTHON_VERSION="$sys_version"
                return 0
            fi
            ;;
    esac
}

# =============================================================================
# Environment Creation Functions
# =============================================================================

create_pixi_environment() {
    local repo_root=$(get_repo_root)

    header "Creating Pixi Environment"

    progress "Initializing pixi project"

    # Check if pixi.toml already exists
    if [[ -f "$repo_root/pixi.toml" ]]; then
        warn "pixi.toml already exists"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            info "Skipping pixi.toml creation"
            return 0
        fi
    fi

    # Create pixi.toml from template
    local template="$repo_root/specs/001-python-env-management/templates/pixi.toml.template"
    if [[ -f "$template" ]]; then
        sed -e "s/{{ENV_NAME}}/$ENV_NAME/g" \
            -e "s/{{PYTHON_VERSION}}/$PYTHON_VERSION/g" \
            "$template" > "$repo_root/pixi.toml"
        progress_done
    else
        # Create minimal pixi.toml
        cat > "$repo_root/pixi.toml" << EOF
[project]
name = "$ENV_NAME"
version = "0.1.0"
channels = ["conda-forge"]
platforms = ["linux-64", "osx-arm64", "osx-64", "win-64"]

[dependencies]
python = "$PYTHON_VERSION.*"
numpy = ">=1.24"
pandas = ">=2.0"
matplotlib = ">=3.7"
jupyterlab = ">=4.0"
EOF
        progress_done
    fi

    progress "Installing dependencies (this may take a few minutes)"
    if pixi install &>/dev/null; then
        progress_done
    else
        progress_fail
        error "Failed to install dependencies"
        echo "  Run 'pixi install' manually to see detailed errors"
        return 1
    fi

    success "Pixi environment created successfully!"
    echo ""
    echo -e "${BOLD}To use your environment:${NC}"
    echo "  pixi shell           # Enter the environment"
    echo "  pixi run python      # Run Python directly"
    echo "  pixi run jupyter lab # Start Jupyter Lab"
    echo "  pixi add <package>   # Add new packages"
}

create_conda_environment() {
    local repo_root=$(get_repo_root)
    local conda_cmd="conda"

    # Prefer mamba if available
    if command_exists mamba; then
        conda_cmd="mamba"
        info "Using mamba for faster installation"
    fi

    header "Creating Conda Environment"

    progress "Generating environment.yml"

    # Create environment.yml from template
    local template="$repo_root/specs/001-python-env-management/templates/environment.yml.template"
    if [[ -f "$template" ]]; then
        sed -e "s/{{ENV_NAME}}/$ENV_NAME/g" \
            -e "s/{{PYTHON_VERSION}}/$PYTHON_VERSION/g" \
            "$template" > "$repo_root/environment.yml"
        progress_done
    else
        # Create minimal environment.yml
        cat > "$repo_root/environment.yml" << EOF
name: $ENV_NAME
channels:
  - conda-forge
  - defaults
dependencies:
  - python=$PYTHON_VERSION
  - numpy>=1.24
  - pandas>=2.0
  - matplotlib>=3.7
  - jupyterlab>=4.0
  - pip
EOF
        progress_done
    fi

    # Also create requirements.txt for pip compatibility
    local req_template="$repo_root/specs/001-python-env-management/templates/requirements.txt.template"
    if [[ -f "$req_template" ]]; then
        cp "$req_template" "$repo_root/requirements.txt"
    fi

    progress "Creating conda environment (this may take several minutes)"
    if $conda_cmd env create -f "$repo_root/environment.yml" -y &>/dev/null; then
        progress_done
    else
        progress_fail
        warn "Environment creation failed or environment already exists"
        echo "  Attempting to update existing environment..."
        if $conda_cmd env update -f "$repo_root/environment.yml" --prune &>/dev/null; then
            success "Environment updated successfully"
        else
            error "Failed to create/update environment"
            echo "  Run '$conda_cmd env create -f environment.yml' manually to see errors"
            return 1
        fi
    fi

    success "Conda environment created successfully!"
    echo ""
    echo -e "${BOLD}To use your environment:${NC}"
    echo "  conda activate $ENV_NAME"
    echo "  jupyter lab                    # Start Jupyter Lab"
    echo "  conda install <package>        # Add new packages"
    echo "  conda env export > environment.yml  # Export environment"
}

create_venv_environment() {
    local repo_root=$(get_repo_root)
    local venv_dir="$repo_root/venv"

    header "Creating Virtual Environment"

    progress "Creating venv directory"

    if [[ -d "$venv_dir" ]]; then
        warn "venv directory already exists"
        read -p "Remove and recreate? [y/N]: " recreate
        if [[ "$recreate" =~ ^[Yy]$ ]]; then
            rm -rf "$venv_dir"
        else
            info "Using existing venv"
        fi
    fi

    if [[ ! -d "$venv_dir" ]]; then
        python3 -m venv "$venv_dir"
    fi
    progress_done

    # Create requirements.txt from template
    progress "Generating requirements.txt"
    local template="$repo_root/specs/001-python-env-management/templates/requirements.txt.template"
    if [[ -f "$template" ]]; then
        cp "$template" "$repo_root/requirements.txt"
        progress_done
    else
        # Create minimal requirements.txt
        cat > "$repo_root/requirements.txt" << EOF
numpy>=1.24.0
pandas>=2.0.0
matplotlib>=3.7.0
jupyterlab>=4.0.0
EOF
        progress_done
    fi

    progress "Installing dependencies"
    if "$venv_dir/bin/pip" install -r "$repo_root/requirements.txt" &>/dev/null; then
        progress_done
    else
        progress_fail
        error "Failed to install some dependencies"
        echo "  Run 'pip install -r requirements.txt' manually to see errors"
    fi

    success "Virtual environment created successfully!"
    echo ""
    echo -e "${BOLD}To use your environment:${NC}"
    echo "  source venv/bin/activate       # Linux/macOS"
    echo "  .\\venv\\Scripts\\activate       # Windows"
    echo "  jupyter lab                    # Start Jupyter Lab"
    echo "  pip install <package>          # Add new packages"
    echo "  pip freeze > requirements.txt  # Export dependencies"
}

# =============================================================================
# Configuration File Functions
# =============================================================================

create_env_config() {
    local repo_root=$(get_repo_root)
    local config_file="$repo_root/.env-config"
    local platform=$(detect_platform)
    local date=$(date +%Y-%m-%d)

    progress "Creating .env-config"

    cat > "$config_file" << EOF
# Python Environment Configuration
# Generated by env-init.sh on $date
# This file documents your environment setup for reproducibility

[environment]
# Tool used to manage this environment (pixi|conda|venv)
tool = $SELECTED_TOOL

# Python version for this project
python_version = $PYTHON_VERSION

# Environment name (used for conda/pixi environments)
env_name = $ENV_NAME

# Creation date
created = $date

# Platform this was created on (for reference)
platform = $platform

[packages]
# Core research dependencies with versions
# Format: package_name = version
# These are tracked automatically by env-sync.sh

[package_notes]
# Documentation for manuscript methods section
# Format: package_name = "Description of how this package is used"
# Example: numpy = "Used for numerical computations in hydrological modeling"

[sync]
# Last sync timestamp (managed by env-sync.sh)
last_sync = $date

# Packages pending documentation
pending_packages =
EOF

    progress_done
}

update_gitignore() {
    local repo_root=$(get_repo_root)
    local gitignore="$repo_root/.gitignore"

    progress "Updating .gitignore"

    # Entries to ensure are present
    local entries=(
        "# Python environments"
        "venv/"
        ".venv/"
        ".pixi/"
        "__pycache__/"
        "*.py[cod]"
        ".ipynb_checkpoints/"
    )

    # Create .gitignore if it doesn't exist
    if [[ ! -f "$gitignore" ]]; then
        touch "$gitignore"
    fi

    for entry in "${entries[@]}"; do
        if ! grep -qF "$entry" "$gitignore" 2>/dev/null; then
            echo "$entry" >> "$gitignore"
        fi
    done

    progress_done
}

# =============================================================================
# From-Config Mode
# =============================================================================

load_from_config() {
    local repo_root=$(get_repo_root)
    local config_file="$repo_root/.env-config"

    if [[ ! -f "$config_file" ]]; then
        error ".env-config not found!"
        echo "  Run 'env-init.sh' without --from-config first to create configuration"
        exit 1
    fi

    header "Loading Configuration from .env-config"

    # Parse config file (simple INI parser)
    SELECTED_TOOL=$(grep -E "^tool\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ')
    PYTHON_VERSION=$(grep -E "^python_version\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ')
    ENV_NAME=$(grep -E "^env_name\s*=" "$config_file" | cut -d'=' -f2 | tr -d ' ')

    if [[ -z "$SELECTED_TOOL" ]] || [[ -z "$PYTHON_VERSION" ]] || [[ -z "$ENV_NAME" ]]; then
        error "Invalid .env-config file"
        echo "  Missing required fields: tool, python_version, or env_name"
        exit 1
    fi

    info "Tool: $SELECTED_TOOL"
    info "Python: $PYTHON_VERSION"
    info "Environment: $ENV_NAME"

    # Verify tool is available
    if ! command_exists "$SELECTED_TOOL" && [[ "$SELECTED_TOOL" != "venv" ]]; then
        error "$SELECTED_TOOL is not installed on this system"
        exit 1
    fi
}

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << EOF
${BOLD}env-init.sh${NC} - Python Environment Initialization

${BOLD}USAGE${NC}
    ./env-init.sh [OPTIONS]

${BOLD}OPTIONS${NC}
    --help, -h          Show this help message
    --from-config       Reproduce environment from existing .env-config
    --tool TOOL         Skip tool selection (pixi|conda|venv)
    --python-version V  Specify Python version (e.g., 3.11)
    --name NAME         Specify environment name
    --quiet, -q         Non-interactive mode (use defaults)
    --no-color          Disable colored output

${BOLD}EXAMPLES${NC}
    # Interactive setup with educational prompts
    ./env-init.sh

    # Quick setup with pixi
    ./env-init.sh --tool pixi --quiet

    # Reproduce from configuration
    ./env-init.sh --from-config

    # Specify all options
    ./env-init.sh --tool conda --python-version 3.11 --name myproject

${BOLD}SUPPORTED TOOLS${NC}
    pixi    Modern package manager (recommended for geospatial)
    conda   Traditional conda/mamba environments
    venv    Python's built-in virtual environments

${BOLD}FILES CREATED${NC}
    .env-config       Environment configuration (always created)
    pixi.toml         Pixi project file (if using pixi)
    environment.yml   Conda environment spec (if using conda)
    requirements.txt  Pip requirements (if using venv or conda)

${BOLD}MORE INFORMATION${NC}
    See docs/environment-guide.md for detailed documentation
EOF
}

# =============================================================================
# Summary Output
# =============================================================================

show_summary() {
    local repo_root=$(get_repo_root)

    header "Setup Complete!"

    echo -e "${BOLD}Created Files:${NC}"
    [[ -f "$repo_root/.env-config" ]] && echo "  ✓ .env-config"
    [[ -f "$repo_root/pixi.toml" ]] && echo "  ✓ pixi.toml"
    [[ -f "$repo_root/environment.yml" ]] && echo "  ✓ environment.yml"
    [[ -f "$repo_root/requirements.txt" ]] && echo "  ✓ requirements.txt"
    [[ -d "$repo_root/venv" ]] && echo "  ✓ venv/"
    [[ -d "$repo_root/.pixi" ]] && echo "  ✓ .pixi/"

    echo ""
    echo -e "${BOLD}Configuration:${NC}"
    echo "  Tool:    $SELECTED_TOOL"
    echo "  Python:  $PYTHON_VERSION"
    echo "  Name:    $ENV_NAME"

    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    case "$SELECTED_TOOL" in
        pixi)
            echo "  1. Run 'pixi shell' to activate the environment"
            echo "  2. Run 'pixi add <package>' to add dependencies"
            echo "  3. Run 'env-sync.sh' after adding packages"
            ;;
        conda|mamba)
            echo "  1. Run 'conda activate $ENV_NAME'"
            echo "  2. Run 'conda install <package>' to add dependencies"
            echo "  3. Run 'env-sync.sh' after adding packages"
            ;;
        venv)
            echo "  1. Run 'source venv/bin/activate'"
            echo "  2. Run 'pip install <package>' to add dependencies"
            echo "  3. Run 'env-sync.sh' after adding packages"
            ;;
    esac

    echo ""
    echo -e "${DIM}Environment configuration saved to .env-config${NC}"
    echo -e "${DIM}Use 'env-init.sh --from-config' to reproduce this setup${NC}"
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                setup_colors
                show_help
                exit 0
                ;;
            --from-config)
                FROM_CONFIG=true
                shift
                ;;
            --tool)
                SELECTED_TOOL="$2"
                shift 2
                ;;
            --python-version)
                PYTHON_VERSION="$2"
                shift 2
                ;;
            --name)
                ENV_NAME="$2"
                shift 2
                ;;
            --quiet|-q)
                QUIET_MODE=true
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

    # Setup colors based on terminal and options
    setup_colors

    header "Python Environment Initialization"

    # Detect platform
    local platform=$(detect_platform)
    info "Detected platform: $platform"

    if [[ "$FROM_CONFIG" == "true" ]]; then
        # Load settings from .env-config
        load_from_config
    else
        # Interactive or quiet setup
        if [[ "$QUIET_MODE" != "true" ]] && [[ -z "$SELECTED_TOOL" ]]; then
            show_tool_comparison
            prompt_tool_selection
        elif [[ -z "$SELECTED_TOOL" ]]; then
            # Quiet mode - auto-select best available tool
            local tools=($(detect_tools))
            if [[ ${#tools[@]} -eq 0 ]]; then
                error "No environment tools available"
                exit 1
            fi
            # Prefer pixi > conda/mamba > venv
            for preferred in pixi mamba conda venv; do
                for t in "${tools[@]}"; do
                    if [[ "$t" == "$preferred" ]]; then
                        SELECTED_TOOL="$t"
                        break 2
                    fi
                done
            done
            info "Auto-selected tool: $SELECTED_TOOL"
        fi

        # Validate selected tool exists
        if [[ "$SELECTED_TOOL" != "venv" ]] && ! command_exists "$SELECTED_TOOL"; then
            error "$SELECTED_TOOL is not installed"
            exit 1
        fi

        # Get Python version
        if [[ -z "$PYTHON_VERSION" ]]; then
            if [[ "$QUIET_MODE" == "true" ]]; then
                PYTHON_VERSION="$DEFAULT_PYTHON_VERSION"
                info "Using default Python version: $PYTHON_VERSION"
            else
                prompt_python_version
            fi
        fi

        # Get environment name
        if [[ -z "$ENV_NAME" ]]; then
            if [[ "$QUIET_MODE" == "true" ]]; then
                ENV_NAME=$(basename "$(pwd)")
                ENV_NAME="${ENV_NAME:-$DEFAULT_ENV_NAME}"
                info "Using environment name: $ENV_NAME"
            else
                prompt_env_name
            fi
        fi
    fi

    # Validate Python version availability
    validate_python_version "$SELECTED_TOOL" "$PYTHON_VERSION"

    # Create the environment
    case "$SELECTED_TOOL" in
        pixi)
            create_pixi_environment
            ;;
        conda|mamba)
            create_conda_environment
            ;;
        venv)
            create_venv_environment
            ;;
        *)
            error "Unknown tool: $SELECTED_TOOL"
            exit 1
            ;;
    esac

    # Create configuration file and update .gitignore
    create_env_config
    update_gitignore

    # Show summary
    show_summary
}

# Run main function
main "$@"
