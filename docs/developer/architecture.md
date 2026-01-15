# res_spec Architecture

This document describes the internal architecture of res_spec for developers who want to understand, extend, or customize the template.

## System Overview

res_spec is a template repository that combines three main components:

1. **Speckit Commands** - Claude Code slash commands for specification-driven development
2. **Environment Scripts** - Bash scripts for reproducible Python environment management
3. **Documentation Templates** - Markdown templates for structured research documentation

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ /speckit.*   │  │ env-*.sh     │  │ Documentation    │  │
│  │ Commands     │  │ Scripts      │  │ Files            │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────────┘  │
└─────────┼─────────────────┼─────────────────────────────────┘
          │                 │
          ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    Core Components                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Templates    │  │ Constitution │  │ .env-config      │  │
│  │ .specify/    │  │ .specify/    │  │ Environment      │  │
│  │ templates/   │  │ memory/      │  │ Tracking         │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    Output Artifacts                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ specs/       │  │ Environment  │  │ Methods          │  │
│  │ NNN-feature/ │  │ Files        │  │ Export           │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
res_spec/
├── .claude/
│   └── commands/                    # Speckit command definitions
│       ├── speckit.specify.md       # Feature specification
│       ├── speckit.plan.md          # Implementation planning
│       ├── speckit.tasks.md         # Task generation
│       ├── speckit.implement.md     # Implementation execution
│       ├── speckit.clarify.md       # Specification clarification
│       ├── speckit.analyze.md       # Cross-artifact analysis
│       ├── speckit.checklist.md     # Custom checklist generation
│       ├── speckit.constitution.md  # Constitution management
│       └── speckit.taskstoissues.md # GitHub issue generation
│
├── .specify/
│   ├── memory/
│   │   └── constitution.md          # Research principles (5 core)
│   ├── scripts/bash/
│   │   ├── env-init.sh              # Environment initialization
│   │   ├── env-sync.sh              # Dependency synchronization
│   │   ├── env-validate.sh          # Environment validation
│   │   ├── export-methods.sh        # Methods section export
│   │   └── init-project.sh          # Project bootstrapping
│   └── templates/
│       ├── spec-template.md         # Feature specification
│       ├── plan-template.md         # Implementation plan
│       ├── tasks-template.md        # Task list
│       ├── checklist-template.md    # Custom checklist
│       └── agent-file-template.md   # CLAUDE.md template
│
├── docs/
│   ├── user/                        # User documentation
│   └── developer/                   # Developer documentation
│
├── specs/                           # Feature specifications
│   └── NNN-feature-name/
│       ├── spec.md                  # Feature specification
│       ├── plan.md                  # Implementation plan
│       ├── tasks.md                 # Task breakdown
│       ├── research.md              # Technical decisions
│       ├── data-model.md            # Data structures
│       └── contracts/               # Interface contracts
│
├── README.md                        # User entry point
├── CONTRIBUTING.md                  # Developer guide
├── CLAUDE.md                        # Agent context
└── .env-config                      # Environment configuration
```

## Component Details

### Speckit Commands

Speckit commands are Claude Code slash commands defined as markdown files. Each command:

1. **Defines a workflow** - Steps the AI agent follows
2. **References templates** - From `.specify/templates/`
3. **Produces artifacts** - Written to `specs/NNN-feature/`

#### Command Lifecycle

```
User invokes /speckit.specify "feature description"
                    │
                    ▼
    ┌───────────────────────────┐
    │ Load command definition   │
    │ .claude/commands/         │
    │ speckit.specify.md        │
    └─────────────┬─────────────┘
                  │
                  ▼
    ┌───────────────────────────┐
    │ Read template             │
    │ .specify/templates/       │
    │ spec-template.md          │
    └─────────────┬─────────────┘
                  │
                  ▼
    ┌───────────────────────────┐
    │ Process with constitution │
    │ .specify/memory/          │
    │ constitution.md           │
    └─────────────┬─────────────┘
                  │
                  ▼
    ┌───────────────────────────┐
    │ Write output              │
    │ specs/NNN-feature/        │
    │ spec.md                   │
    └───────────────────────────┘
```

### Environment Scripts

Environment scripts manage Python environments across pixi, conda, and venv. They share common patterns:

#### Script Conventions

- Located in `.specify/scripts/bash/`
- Named with `env-` prefix for environment scripts
- Use `set -euo pipefail` for safety
- Support `--help`, `--quiet`, and often `--json` flags
- Exit codes: 0 (success), 1 (error), 2+ (specific errors)

#### .env-config Format

The central configuration file tracks environment state:

```ini
[environment]
tool = pixi
python_version = 3.11
env_name = res-spec

[packages]
numpy = 1.26.0
scipy = 1.11.0

[package_notes]
numpy = "Numerical computations for hydrological modeling"
scipy = "Spatial interpolation of climate station data"
```

### Constitution

The constitution (`.specify/memory/constitution.md`) defines five core principles:

1. **Research-First Development** - Features serve scientific goals
2. **Reproducibility & Transparency** - Explicit environment documentation
3. **Documentation as Science Communication** - Why before how
4. **Incremental Implementation with Validation** - MVP + validated steps
5. **Library & Method Integration** - Use established scientific tools

Constitution checks occur during `/speckit.plan` to ensure features align with research principles.

### Templates

Templates in `.specify/templates/` define document structure. They use placeholder syntax:

```markdown
# Feature Specification: {{FEATURE_NAME}}

**Branch**: `{{BRANCH_NAME}}`
**Created**: {{DATE}}

## User Scenarios & Testing

{{USER_STORIES}}
```

## Data Flow

### Specification Workflow

```
/speckit.specify "Research question"
         │
         ▼
    specs/NNN-feature/spec.md
         │
         ▼
/speckit.plan
         │
         ▼
    specs/NNN-feature/plan.md
    specs/NNN-feature/research.md
    specs/NNN-feature/contracts/
         │
         ▼
/speckit.tasks
         │
         ▼
    specs/NNN-feature/tasks.md
         │
         ▼
/speckit.implement
         │
         ▼
    Implementation in src/, notebooks/, etc.
```

### Environment Workflow

```
env-init.sh --tool pixi
         │
         ▼
    Creates pixi.toml, .env-config
         │
         ▼
User installs packages (pixi add numpy)
         │
         ▼
env-sync.sh
         │
         ▼
    Updates .env-config with packages/versions
         │
         ▼
env-sync.sh --package numpy
         │
         ▼
    Prompts for package_notes entry
         │
         ▼
export-methods.sh
         │
         ▼
    Generates methods paragraph for manuscript
```

## Extension Points

### Adding New Commands

1. Create `.claude/commands/speckit.yourcommand.md`
2. Define workflow and template references
3. Optionally add template in `.specify/templates/`
4. Update CLAUDE.md if command should be discoverable

### Adding Environment Scripts

1. Create `.specify/scripts/bash/script-name.sh`
2. Follow conventions (set -euo pipefail, --help, etc.)
3. Integrate with .env-config if needed
4. Document in CONTRIBUTING.md

### Customizing the Constitution

1. Edit `.specify/memory/constitution.md`
2. Update dependent templates that reference principles
3. Test with `/speckit.plan` to verify validation works

## Design Decisions

### Why Specification-Driven?

Research code often grows organically without clear documentation. By requiring specifications first, res_spec:

- Forces clarity about what you're building and why
- Creates documentation as a byproduct of development
- Enables constitution checks before implementation

### Why Multiple Environment Tools?

Different research domains have different needs:

- **pixi** - Best for geospatial (GDAL, PROJ, etc.)
- **conda** - Widely used in scientific Python
- **venv** - Lightweight, standard library

Supporting all three maximizes adoption across research communities.

### Why Bash Scripts?

Bash scripts:

- Work everywhere (macOS, Linux, WSL)
- No additional dependencies
- Easy to understand and modify
- Integrate well with git hooks and CI

## See Also

- [Extending Speckit](extending-speckit.md) - Adding custom commands
- [Testing Guide](testing-guide.md) - Validation procedures
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
