# Contributing to res_spec

Thank you for your interest in improving the res_spec template!

## Welcome & Overview

This guide is for developers who want to:

- Extend res_spec functionality with new scripts or commands
- Customize the template for their lab or research group
- Contribute improvements back to the project

If you're a researcher using res_spec for your project, see [README.md](README.md) instead.

### Types of Contributions

We welcome contributions of all kinds:

- **Bug fixes**: Found something broken? We appreciate fixes
- **Documentation**: Improve guides, add examples, fix typos
- **New features**: Environment scripts, speckit commands, templates
- **Lab customizations**: Share how you've adapted res_spec for your domain

## Quick Start for Contributors

### For Simple Changes (Documentation, Typos)

1. Fork the repository
2. Make your changes directly on GitHub or clone locally
3. Submit a pull request with a clear description

### For New Features or Large Changes

1. **Open an issue first** to discuss your idea
2. Wait for maintainer feedback
3. Fork and create a feature branch
4. Implement with tests/validation
5. Submit PR referencing the issue

```bash
# Example workflow for a new feature
git clone https://github.com/YOUR-USERNAME/res-spec.git
cd res-spec
git checkout -b feature/add-export-format
# ... make changes ...
git commit -m "feat: add CSV export format to env-sync"
git push origin feature/add-export-format
# Then open PR on GitHub
```

## Project Architecture

### Directory Structure

```
res_spec/
├── .claude/
│   └── commands/                # Speckit command prompts
│       ├── speckit.specify.md   # Feature specification
│       ├── speckit.plan.md      # Implementation planning
│       ├── speckit.tasks.md     # Task generation
│       ├── speckit.implement.md # Implementation execution
│       └── speckit.*.md         # Other commands
├── .specify/
│   ├── memory/
│   │   └── constitution.md      # Research principles (5 core principles)
│   ├── scripts/bash/            # Helper scripts
│   │   ├── env-init.sh          # Environment initialization
│   │   ├── env-sync.sh          # Dependency synchronization
│   │   ├── env-validate.sh      # Environment validation
│   │   ├── export-methods.sh    # Methods section export
│   │   └── init-project.sh      # Project bootstrapping
│   └── templates/               # Spec templates
│       ├── spec-template.md     # Feature specification
│       ├── plan-template.md     # Implementation plan
│       ├── tasks-template.md    # Task list
│       └── checklist-template.md
├── docs/
│   ├── user/                    # User-facing documentation
│   │   ├── quickstart.md        # Complete walkthrough
│   │   ├── environment-guide.md # Tool choice guide
│   │   ├── pixi-workflows.md    # Geospatial workflows
│   │   └── troubleshooting.md   # Common issues
│   └── developer/               # Developer documentation
│       ├── architecture.md      # System design
│       ├── extending-speckit.md # Adding commands
│       └── testing-guide.md     # Testing procedures
├── specs/                       # Feature specifications (examples)
│   ├── 001-python-env-management/
│   └── 002-speckit-research-integration/
├── README.md                    # User-centric entry point
├── CONTRIBUTING.md              # This file
└── CLAUDE.md                    # Agent context
```

### Key Components

**Speckit Commands** (`.claude/commands/`)

The speckit commands are Claude Code slash commands that guide researchers through the specification-driven workflow:

- Commands are markdown files with embedded prompts
- They read from templates in `.specify/templates/`
- They write to `specs/NNN-feature-name/` directories
- The constitution in `.specify/memory/` provides guardrails

**Helper Scripts** (`.specify/scripts/bash/`)

Bash scripts provide environment management and utility functions:

- All scripts follow `set -euo pipefail` for safety
- Scripts support `--help`, `--quiet`, and often `--json` flags
- Common utilities are in `common.sh` (if present)
- Exit codes: 0 (success), 1 (general error), 2+ (specific errors)

**Templates** (`.specify/templates/`)

Templates define the structure of generated specification documents:

- Templates use placeholder syntax for dynamic content
- They're filled by speckit commands during execution
- Template changes affect all future specifications

## Development Setup

### Prerequisites

- Git
- Bash 4.0+ (check with `bash --version`)
- Python 3.9+
- Claude Code with speckit commands (for testing workflow)

### Setup Steps

1. **Fork and clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/res-spec.git
   cd res-spec
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Initialize environment for testing**
   ```bash
   ./.specify/scripts/bash/env-init.sh --tool venv --quiet
   ```

4. **Make your changes**
   - Edit scripts, templates, or documentation
   - Test locally before committing

5. **Validate changes**
   ```bash
   # For script changes
   bash -n ./.specify/scripts/bash/your-script.sh  # Syntax check

   # For documentation
   # Check links manually or use a markdown linter
   ```

## Adding Environment Scripts

### Location

All environment management scripts go in `.specify/scripts/bash/`

### Naming Convention

- Use kebab-case: `env-action-name.sh`
- Prefix with `env-` for environment-related scripts
- Use descriptive verbs: validate, sync, init, export

### Script Template

New scripts should follow this structure:

```bash
#!/usr/bin/env bash
# Description: What this script does
# Usage: ./script-name.sh [OPTIONS]
#
# Options:
#   --help     Show this help message
#   --quiet    Suppress non-essential output
#   --json     Output in JSON format (if applicable)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Display help
show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# Parse arguments
QUIET=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) show_help ;;
        --quiet|-q) QUIET=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Main implementation
main() {
    # Your script logic here
    echo "Script executed successfully"
}

main "$@"
```

### Integration Points

New scripts should integrate with:

- `.env-config` for reading/writing environment configuration
- Existing scripts for common operations (don't duplicate logic)
- Exit codes: 0 (success), 1 (error), 2+ (specific errors)

### Testing Requirements

Before submitting:

1. Test with all environment tools (pixi, conda, venv) if applicable
2. Test error conditions (missing files, invalid input)
3. Verify `--help` output is accurate
4. Check exit codes are correct
5. Test on macOS and Linux if possible

## Customizing the Constitution

### When to Customize

Consider customizing `.specify/memory/constitution.md` when:

- Your lab has domain-specific research principles
- You need additional quality gates for your field
- Your workflow differs from template assumptions

### Customization Process

1. **Understand current principles**

   Read `.specify/memory/constitution.md` thoroughly. The five core principles are:
   - Research-First Development
   - Reproducibility & Transparency
   - Documentation as Science Communication
   - Incremental Implementation with Validation
   - Library & Method Integration

2. **Document your changes**

   Before modifying, create a brief rationale for additions or changes.

3. **Update the constitution**

   Add new principles or modify existing ones following the established format.

4. **Update dependent templates**

   The following files reference the constitution and may need updates:
   - `.specify/templates/plan-template.md` (constitution check section)
   - `.claude/commands/speckit.plan.md` (validation prompts)

5. **Test validation**

   Create a test specification and run through the full workflow to ensure constitution checks work correctly.

### Example: Adding a Domain-Specific Principle

```markdown
### Principle VI: Geospatial Data Integrity

**Rationale**: Geospatial research requires explicit coordinate reference system documentation.

- **CRS Documentation**: All spatial data operations MUST document input and output CRS
- **Transformation Logging**: CRS transformations MUST be logged with transformation parameters
- **Validation**: Spatial extent validation required before analysis
```

### Version Management

When customizing for your lab:

- Document the base version you started from
- Keep a changelog of your modifications
- Consider contributing generally-useful additions back upstream

## Extending Speckit Commands

### Command Architecture

Speckit commands in `.claude/commands/` follow this pattern:

1. **Command file** defines the prompt and workflow
2. **Template files** provide document structure
3. **Helper scripts** perform validation and generation

### Adding a New Command

1. **Create the command file**

   `.claude/commands/speckit.yourcommand.md`

   ```markdown
   # /speckit.yourcommand

   [Description of what this command does]

   ## Prerequisites

   - [What must exist before running]

   ## Process

   1. [Step 1]
   2. [Step 2]

   ## Output

   - [What gets generated]
   ```

2. **Add template if needed**

   `.specify/templates/yourcommand-template.md`

3. **Add helper script if needed**

   `.specify/scripts/bash/yourcommand-helper.sh`

4. **Update CLAUDE.md**

   Add your command to the agent context if it should be discoverable.

### Example: Adding a Review Command

```markdown
# /speckit.review

Review a completed feature specification for constitution compliance and completeness.

## Prerequisites

- Feature specification exists in `specs/NNN-feature-name/`
- spec.md, plan.md, and tasks.md are complete

## Process

1. Read the feature specification
2. Check constitution compliance for each principle
3. Verify all acceptance criteria are testable
4. Generate review report

## Output

- `specs/NNN-feature-name/review.md` - Review findings and recommendations
```

## Testing Your Changes

### Before Submitting a PR

#### Documentation Changes

- [ ] All links are functional (relative paths work)
- [ ] Code examples are accurate and copy-pasteable
- [ ] Spelling and grammar checked
- [ ] Formatting is consistent with existing docs

#### Script Changes

- [ ] Script runs without errors (`bash -n` for syntax)
- [ ] `--help` output is accurate and helpful
- [ ] Error messages are clear and actionable
- [ ] Exit codes are correct (0 for success)
- [ ] Tested on target platforms (macOS, Linux)

#### Template Changes

- [ ] Generated output is valid markdown
- [ ] Placeholders are properly documented
- [ ] Dependent commands still work correctly

### Integration Testing

Test the full workflow with your changes:

```bash
# 1. Create a test specification
/speckit.specify "Test feature for validation"

# 2. Run through planning
/speckit.plan

# 3. Generate tasks
/speckit.tasks

# 4. Verify generated files are correct
ls -la specs/NNN-test-feature/
```

### Common Pitfalls

- **Hardcoded paths**: Use `$SCRIPT_DIR` or relative paths
- **Missing error handling**: Always check command success
- **Inconsistent output**: Match existing script output formats
- **Breaking changes**: Ensure backward compatibility or document migration

## Commit Message Conventions

### Format

```
<type>: <subject>

<body>
```

### Types

- `feat:` New feature or capability
- `fix:` Bug fix
- `docs:` Documentation changes only
- `refactor:` Code restructuring without behavior change
- `test:` Adding or updating tests
- `chore:` Maintenance tasks (dependencies, configs)

### Examples

```
feat: add CSV export format to env-sync

Add --format csv option to env-sync.sh for spreadsheet compatibility.
Useful for sharing dependency lists with non-technical collaborators.
```

```
fix: handle spaces in project paths

env-init.sh now correctly handles directory paths containing spaces
by quoting all path variables.

Fixes #42
```

```
docs: add troubleshooting section for conda conflicts

Document the common case where conda and pixi have conflicting
environment variables and how to resolve it.
```

## Pull Request Process

1. **Ensure your branch is current**
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Push your branch**
   ```bash
   git push -u origin feature/your-feature-name
   ```

3. **Create the pull request**

   Use a descriptive title and fill out the PR template:

   ```markdown
   ## Summary

   Brief description of changes.

   ## Changes

   - Added X
   - Modified Y
   - Fixed Z

   ## Testing

   How you tested these changes:
   - [ ] Tested on macOS
   - [ ] Tested on Linux
   - [ ] Ran full speckit workflow

   ## Related Issues

   Closes #NNN (if applicable)
   ```

4. **Address review feedback**

   - Respond to all comments
   - Make requested changes
   - Push updates to the same branch

5. **After merge**

   - Delete your feature branch
   - Pull latest main to your fork

## Code of Conduct

We follow the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

In summary: Be respectful, collaborative, and constructive. We're all here to make research more reproducible.

## Questions & Support

- **GitHub Issues**: For bugs, feature requests, and questions
- **GitHub Discussions**: For ideas and general discussion
- **Documentation**: Check `docs/developer/` for detailed guides

---

Thank you for contributing to res_spec! Your improvements help researchers everywhere produce more reproducible science.
