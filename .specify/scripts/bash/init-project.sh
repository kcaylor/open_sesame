#!/usr/bin/env bash
# Description: Bootstrap a new research project from the res_spec template
# Usage: ./init-project.sh [OPTIONS]
#
# Options:
#   --project-name NAME   Set project name (lowercase, hyphens allowed)
#   --domain DOMAIN       Set research domain description
#   --env-tool TOOL       Set environment tool [pixi|conda|venv]
#   --python-version VER  Set Python version (default: 3.11)
#   --quiet               Skip interactive prompts, use defaults
#   --dry-run             Show what would be done without making changes
#   --force               Reinitialize an already-initialized project
#   --help                Display this help message
#
# Examples:
#   ./init-project.sh
#   ./init-project.sh --project-name my-analysis --domain "hydrology" --env-tool pixi
#   ./init-project.sh --dry-run --project-name test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Default values
PROJECT_NAME=""
RESEARCH_DOMAIN=""
ENV_TOOL=""
PYTHON_VERSION="3.11"
QUIET=false
DRY_RUN=false
FORCE=false

# Colors for output (if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Display help message
show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# Print colored message
print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

# Validate project name format
validate_project_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        return 1
    fi
    return 0
}

# Validate Python version format
validate_python_version() {
    local version="$1"
    if [[ ! "$version" =~ ^3\.(9|10|11|12)$ ]]; then
        return 1
    fi
    return 0
}

# Check if environment tool is available
check_env_tool() {
    local tool="$1"
    case "$tool" in
        pixi)
            if ! command -v pixi &>/dev/null; then
                return 1
            fi
            ;;
        conda)
            if ! command -v conda &>/dev/null; then
                return 1
            fi
            ;;
        venv)
            if ! command -v python3 &>/dev/null; then
                return 1
            fi
            ;;
    esac
    return 0
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                ;;
            --project-name)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --domain)
                RESEARCH_DOMAIN="$2"
                shift 2
                ;;
            --env-tool)
                ENV_TOOL="$2"
                shift 2
                ;;
            --python-version)
                PYTHON_VERSION="$2"
                shift 2
                ;;
            --quiet|-q)
                QUIET=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Run with --help for usage information."
                exit 1
                ;;
        esac
    done
}

# Check preconditions
check_preconditions() {
    # Check we're in res_spec root
    if [[ ! -d "$PROJECT_ROOT/.specify" ]]; then
        print_error "This script must be run from the res_spec repository root."
        echo "Could not find .specify/ directory in: $PROJECT_ROOT"
        exit 1
    fi

    # Check git is installed
    if ! command -v git &>/dev/null; then
        print_error "Git is required but not found. Please install git."
        exit 1
    fi

    # Check if already initialized
    if [[ -f "$PROJECT_ROOT/.specify/.initialized" ]] && [[ "$FORCE" != "true" ]]; then
        print_warning "Project appears already initialized."
        echo ""
        echo "Initialization marker found at: $PROJECT_ROOT/.specify/.initialized"
        echo "Use --force to re-initialize this project."
        exit 1
    fi
}

# Interactive prompt for project name
prompt_project_name() {
    if [[ -n "$PROJECT_NAME" ]]; then
        if ! validate_project_name "$PROJECT_NAME"; then
            print_error "Invalid project name: $PROJECT_NAME"
            echo "Project name must be lowercase letters, numbers, and hyphens only."
            exit 1
        fi
        return
    fi

    if [[ "$QUIET" == "true" ]]; then
        print_error "Project name required in quiet mode. Use --project-name"
        exit 1
    fi

    while true; do
        echo ""
        echo -e "${BLUE}Enter project name (lowercase, hyphens allowed):${NC}"
        echo "Example: watershed-hydrology-analysis"
        read -r -p "> " PROJECT_NAME

        if [[ -z "$PROJECT_NAME" ]]; then
            print_warning "Project name cannot be empty."
            continue
        fi

        if validate_project_name "$PROJECT_NAME"; then
            break
        else
            print_warning "Invalid name. Use only lowercase letters, numbers, and hyphens."
        fi
    done
}

# Interactive prompt for research domain
prompt_research_domain() {
    if [[ -n "$RESEARCH_DOMAIN" ]]; then
        return
    fi

    if [[ "$QUIET" == "true" ]]; then
        RESEARCH_DOMAIN="research project"
        return
    fi

    echo ""
    echo -e "${BLUE}Enter research domain (for documentation):${NC}"
    echo "Example: hydrological modeling, spatial ecology, bioinformatics"
    read -r -p "> " RESEARCH_DOMAIN

    if [[ -z "$RESEARCH_DOMAIN" ]]; then
        RESEARCH_DOMAIN="research project"
    fi
}

# Interactive prompt for environment tool
prompt_env_tool() {
    if [[ -n "$ENV_TOOL" ]]; then
        case "$ENV_TOOL" in
            pixi|conda|venv) ;;
            *)
                print_error "Invalid environment tool: $ENV_TOOL"
                echo "Must be one of: pixi, conda, venv"
                exit 1
                ;;
        esac
        return
    fi

    if [[ "$QUIET" == "true" ]]; then
        # Default to pixi if available, then conda, then venv
        if command -v pixi &>/dev/null; then
            ENV_TOOL="pixi"
        elif command -v conda &>/dev/null; then
            ENV_TOOL="conda"
        else
            ENV_TOOL="venv"
        fi
        return
    fi

    echo ""
    echo -e "${BLUE}Choose Python environment tool:${NC}"
    echo "  1. pixi (recommended for geospatial research)"
    echo "  2. conda (widely compatible)"
    echo "  3. venv (lightweight, pip-based)"
    echo ""
    read -r -p "Your choice [1]: " choice

    case "${choice:-1}" in
        1) ENV_TOOL="pixi" ;;
        2) ENV_TOOL="conda" ;;
        3) ENV_TOOL="venv" ;;
        *)
            print_warning "Invalid choice, defaulting to pixi"
            ENV_TOOL="pixi"
            ;;
    esac
}

# Interactive prompt for Python version (only for conda/venv)
prompt_python_version() {
    if [[ "$ENV_TOOL" == "pixi" ]]; then
        return
    fi

    if [[ "$QUIET" == "true" ]]; then
        return
    fi

    echo ""
    echo -e "${BLUE}Python version [${PYTHON_VERSION}]:${NC}"
    read -r -p "> " version

    if [[ -n "$version" ]]; then
        if validate_python_version "$version"; then
            PYTHON_VERSION="$version"
        else
            print_warning "Invalid version. Using default: $PYTHON_VERSION"
        fi
    fi
}

# Action 1: Reset git history
action_reset_git() {
    print_info "Resetting git history..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would remove git remote origin"
        echo "  [DRY RUN] Would remove .git directory"
        echo "  [DRY RUN] Would initialize fresh git repository"
        echo "  [DRY RUN] Would create initial commit"
        return
    fi

    cd "$PROJECT_ROOT"

    # Remove remote if exists
    if git remote get-url origin &>/dev/null; then
        git remote remove origin
    fi

    # Remove git history
    rm -rf .git

    # Initialize fresh
    git init
    git add .
    git commit -m "Initial commit: Initialized from res_spec template

Project: $PROJECT_NAME
Domain: $RESEARCH_DOMAIN
Environment: $ENV_TOOL"

    print_success "  Git history reset complete"
}

# Action 2: Remove template examples
action_remove_examples() {
    print_info "Removing template examples..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would remove specs/001-python-env-management/"
        echo "  [DRY RUN] Would remove specs/002-speckit-research-integration/"
        echo "  [DRY RUN] Would remove specs/003-user-centric-docs/"
        return
    fi

    cd "$PROJECT_ROOT"

    # Remove example specs
    if [[ -d "specs/001-python-env-management" ]]; then
        rm -rf "specs/001-python-env-management"
    fi
    if [[ -d "specs/002-speckit-research-integration" ]]; then
        rm -rf "specs/002-speckit-research-integration"
    fi
    if [[ -d "specs/003-user-centric-docs" ]]; then
        rm -rf "specs/003-user-centric-docs"
    fi

    print_success "  Template examples removed"
}

# Action 3: Customize README
action_customize_readme() {
    print_info "Customizing README.md..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would replace [Your Name/Lab] with project name"
        echo "  [DRY RUN] Would replace [your-org] placeholders"
        echo "  [DRY RUN] Would update citation block"
        return
    fi

    local readme="$PROJECT_ROOT/README.md"

    if [[ -f "$readme" ]]; then
        # Replace placeholders
        sed -i.bak "s/\[Your Name\/Lab\]/$PROJECT_NAME/g" "$readme"
        sed -i.bak "s/\[your-org\]/$PROJECT_NAME/g" "$readme"

        # Update project description in citation
        sed -i.bak "s/Research Specification Template/$PROJECT_NAME - $RESEARCH_DOMAIN/g" "$readme"

        rm -f "$readme.bak"

        print_success "  README.md customized"
    else
        print_warning "  README.md not found, skipping customization"
    fi
}

# Action 4: Initialize environment
action_init_environment() {
    print_info "Initializing $ENV_TOOL environment..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would run env-init.sh --tool $ENV_TOOL"
        return
    fi

    local env_init="$SCRIPT_DIR/env-init.sh"

    if [[ ! -x "$env_init" ]]; then
        print_warning "  env-init.sh not found or not executable"
        echo "  You can initialize your environment manually later:"
        echo "  ./.specify/scripts/bash/env-init.sh --tool $ENV_TOOL"
        return
    fi

    # Check if environment tool is available
    if ! check_env_tool "$ENV_TOOL"; then
        print_error "$ENV_TOOL is not installed."
        echo ""
        case "$ENV_TOOL" in
            pixi)
                echo "To install pixi: https://prefix.dev/docs/pixi/overview"
                ;;
            conda)
                echo "To install conda: https://docs.conda.io/en/latest/miniconda.html"
                ;;
        esac
        echo ""
        echo "Alternatively, re-run with --env-tool venv to use Python's built-in venv."
        exit 1
    fi

    # Run env-init
    if [[ "$ENV_TOOL" == "pixi" ]]; then
        "$env_init" --tool pixi --quiet || {
            print_warning "  Environment initialization had issues. You may need to run manually."
        }
    else
        "$env_init" --tool "$ENV_TOOL" --python-version "$PYTHON_VERSION" --quiet || {
            print_warning "  Environment initialization had issues. You may need to run manually."
        }
    fi

    print_success "  Environment initialized"
}

# Action 5: Create initialization marker
action_create_marker() {
    print_info "Creating initialization marker..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would create .specify/.initialized with project metadata"
        return
    fi

    cat > "$PROJECT_ROOT/.specify/.initialized" <<EOF
project_name: $PROJECT_NAME
research_domain: $RESEARCH_DOMAIN
environment_tool: $ENV_TOOL
python_version: $PYTHON_VERSION
initialized_at: $(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
template_version: 1.0.0
EOF

    print_success "  Initialization marker created"
}

# Action 6: Display next steps
action_show_next_steps() {
    echo ""
    print_success "Project initialized successfully!"
    echo ""
    echo "Project: $PROJECT_NAME"
    echo "Domain: $RESEARCH_DOMAIN"
    echo "Environment: $ENV_TOOL ($PYTHON_VERSION)"
    echo ""
    echo "Next steps:"
    echo ""

    # Show environment-specific activation command
    case "$ENV_TOOL" in
        pixi)
            echo "  1. Activate your environment:"
            echo "     pixi shell"
            ;;
        conda)
            echo "  1. Activate your environment:"
            echo "     conda activate $PROJECT_NAME"
            ;;
        venv)
            echo "  1. Activate your environment:"
            echo "     source .venv/bin/activate"
            ;;
    esac

    echo ""
    echo "  2. Create your first feature specification:"
    echo "     /speckit.specify \"Your research question or analysis task\""
    echo ""
    echo "  3. Review the quickstart guide:"
    echo "     docs/user/quickstart.md"
    echo ""
    print_success "Happy researching!"
}

# Show dry-run summary
show_dry_run_summary() {
    echo ""
    echo -e "${YELLOW}[DRY RUN] Would perform the following actions:${NC}"
    echo ""
    echo "  1. Reset git history"
    echo "  2. Remove template examples:"
    echo "     - specs/001-python-env-management/"
    echo "     - specs/002-speckit-research-integration/"
    echo "     - specs/003-user-centric-docs/"
    echo "  3. Customize README.md with project name: $PROJECT_NAME"
    echo "  4. Initialize environment: $ENV_TOOL ($PYTHON_VERSION)"
    echo "  5. Create .specify/.initialized marker"
    echo ""
    echo "Run without --dry-run to apply these changes."
}

# Main function
main() {
    parse_args "$@"
    check_preconditions

    echo ""
    print_info "res_spec Project Initialization"
    echo "================================"

    # Gather information
    prompt_project_name
    prompt_research_domain
    prompt_env_tool
    prompt_python_version

    # Show dry-run summary if applicable
    if [[ "$DRY_RUN" == "true" ]]; then
        show_dry_run_summary
        action_reset_git
        action_remove_examples
        action_customize_readme
        action_init_environment
        action_create_marker
        exit 0
    fi

    # Confirm before proceeding (unless quiet)
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        echo "Ready to initialize project with:"
        echo "  Project name: $PROJECT_NAME"
        echo "  Domain: $RESEARCH_DOMAIN"
        echo "  Environment: $ENV_TOOL"
        if [[ "$ENV_TOOL" != "pixi" ]]; then
            echo "  Python: $PYTHON_VERSION"
        fi
        echo ""
        read -r -p "Proceed? [Y/n] " confirm
        if [[ "${confirm:-y}" =~ ^[Nn] ]]; then
            echo "Initialization cancelled."
            exit 0
        fi
    fi

    echo ""

    # Execute actions
    action_reset_git
    action_remove_examples
    action_customize_readme
    action_init_environment
    action_create_marker
    action_show_next_steps
}

main "$@"
