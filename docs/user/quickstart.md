# Quickstart Guide

A complete walkthrough from project creation to manuscript methods export.

**Time to complete**: 20-30 minutes

## What You'll Learn

By the end of this guide, you will have:

1. Created a new research project from the res_spec template
2. Written your first feature specification
3. Generated an implementation plan
4. Installed and documented scientific packages
5. Exported a methods paragraph for your manuscript

## Prerequisites

Before starting, ensure you have:

- **Git** installed (`git --version` to check)
- **Python 3.9+** installed (`python3 --version` to check)
- **Claude Code** with speckit commands
- One of: **pixi**, **conda**, or **python** (for venv)

---

## Part 1: Project Setup

### Step 1: Clone the Template

```bash
git clone https://github.com/ecohydro/res-spec.git my-research-project
cd my-research-project
```

> **What this does**: Creates a copy of the res_spec template in a new directory called `my-research-project`.

### Step 2: Initialize Your Project

```bash
./.specify/scripts/bash/init-project.sh
```

You'll see interactive prompts:

```
res_spec Project Initialization
================================

Enter project name (lowercase, hyphens allowed):
Example: watershed-hydrology-analysis
> rainfall-analysis

Enter research domain (for documentation):
Example: hydrological modeling, spatial ecology, bioinformatics
> hydrology and climate science

Choose Python environment tool:
  1. pixi (recommended for geospatial research)
  2. conda (widely compatible)
  3. venv (lightweight, pip-based)

Your choice [1]: 1

Ready to initialize project with:
  Project name: rainfall-analysis
  Domain: hydrology and climate science
  Environment: pixi

Proceed? [Y/n] y
```

> **What this does**:
> - Resets the git history so you start fresh
> - Removes template example specifications
> - Customizes the README with your project name
> - Initializes your Python environment
> - Creates a marker file tracking your project setup

**Expected output**:

```
Resetting git history...
  Git history reset complete
Removing template examples...
  Template examples removed
Customizing README.md...
  README.md customized
Initializing pixi environment...
  Environment initialized
Creating initialization marker...
  Initialization marker created

Project initialized successfully!

Project: rainfall-analysis
Domain: hydrology and climate science
Environment: pixi (3.11)

Next steps:

  1. Activate your environment:
     pixi shell

  2. Create your first feature specification:
     /speckit.specify "Your research question or analysis task"

  3. Review the quickstart guide:
     docs/user/quickstart.md

Happy researching!
```

### Step 3: Activate Your Environment

```bash
pixi shell  # or: conda activate rainfall-analysis, source .venv/bin/activate
```

> **What this does**: Activates the Python environment so packages you install are tracked and isolated from other projects.

### Troubleshooting: Project Setup

**Problem**: `init-project.sh: command not found`

**Solution**: Make sure you're in the project root directory and use the full path:
```bash
./.specify/scripts/bash/init-project.sh
```

**Problem**: `pixi is not installed`

**Solution**: Install pixi from https://prefix.dev/docs/pixi/overview or use `--env-tool conda` or `--env-tool venv` instead.

---

## Part 2: Your First Feature Specification

Now let's specify our first research feature. In Claude Code:

### Step 1: Run the Specify Command

```
/speckit.specify "Analyze rainfall patterns in California using kriging interpolation"
```

> **What this does**: Creates a feature specification that documents:
> - What you want to build and why
> - User stories (who uses this and how)
> - Acceptance criteria (how you know it works)
> - Requirements and assumptions

**Expected output structure**:

A new directory is created: `specs/001-rainfall-kriging/` containing:

```
specs/001-rainfall-kriging/
└── spec.md         # Your feature specification
```

### Step 2: Review the Specification

Open `specs/001-rainfall-kriging/spec.md` and you'll see:

```markdown
# Feature Specification: Rainfall Pattern Analysis with Kriging

**Feature Branch**: `001-rainfall-kriging`
**Created**: 2025-12-29
**Status**: Draft

## User Scenarios & Testing

### User Story 1 - Spatial Interpolation (Priority: P1)

A researcher needs to interpolate sparse rainfall station data
to create continuous precipitation maps for watershed modeling.

**Acceptance Scenarios**:

1. **Given** rainfall data from weather stations, **When** I run
   the kriging interpolation, **Then** I get a continuous raster
   of estimated precipitation...

[... continues with requirements, assumptions, etc.]
```

> **Why this matters for reproducibility**: By specifying what you're building before you build it, you create documentation that explains the scientific rationale, not just the code.

### Troubleshooting: Specification

**Problem**: The specification doesn't match my research goals

**Solution**: Edit `spec.md` directly or run `/speckit.clarify` to refine the specification through follow-up questions.

---

## Part 3: Planning Your Implementation

Now let's create an implementation plan.

### Step 1: Run the Plan Command

```
/speckit.plan
```

> **What this does**: Creates an implementation plan that:
> - Checks your feature against the research constitution
> - Designs the technical approach
> - Identifies dependencies and risks
> - Creates interface contracts for key components

**Expected output structure**:

```
specs/001-rainfall-kriging/
├── spec.md           # Your specification
├── plan.md           # Implementation plan
├── research.md       # Technical decisions
├── data-model.md     # Data structure definitions
└── contracts/        # Interface specifications
    └── ...
```

### Step 2: Constitution Check

The plan includes a constitution check:

```markdown
## Constitution Check

### Principle I: Research-First Development ✅ PASS

**Scientific Purpose**: Kriging interpolation serves the research
objective of understanding spatial rainfall patterns for
watershed modeling.

### Principle II: Reproducibility & Transparency ✅ PASS

**Environment Specification**: Using pixi with explicit package
versions tracked in .env-config.

[... continues for all 5 principles]

### Gate Decision: ✅ PROCEED
```

> **Why this matters**: The constitution check ensures your feature aligns with reproducible research practices before you start coding.

### Troubleshooting: Planning

**Problem**: Constitution check fails

**Solution**: Review the failed principle and adjust your approach. Common issues:
- Missing scientific rationale (Principle I)
- Environment not documented (Principle II)
- No validation strategy (Principle IV)

---

## Part 4: Implementation

Now generate actionable tasks:

### Step 1: Generate Tasks

```
/speckit.tasks
```

**Expected output**:

```
specs/001-rainfall-kriging/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── contracts/
└── tasks.md          # Actionable task list
```

### Step 2: Review Tasks

The tasks.md file contains a prioritized checklist:

```markdown
# Tasks: Rainfall Pattern Analysis with Kriging

## Phase 1: Setup

- [ ] T001 Create src/kriging/ module directory
- [ ] T002 Set up data loading utilities

## Phase 2: Core Implementation

- [ ] T003 Implement variogram calculation
- [ ] T004 Implement ordinary kriging algorithm
- [ ] T005 Add cross-validation functionality

[... continues]
```

### Step 3: Start Implementing

```
/speckit.implement
```

> **What this does**: Guides you through implementing each task, running environment validation, and tracking progress.

---

## Part 5: Package Documentation

As you implement, you'll install scientific packages. Here's how to document them for your methods section.

### Step 1: Install Packages

```bash
pixi add scipy pandas geopandas rasterio
# or: conda install scipy pandas geopandas rasterio
```

### Step 2: Sync Environment Tracking

```bash
./.specify/scripts/bash/env-sync.sh
```

**Expected output**:

```
Syncing environment packages...
  Found 4 new packages
  Updated .env-config

Packages added:
  scipy = 1.11.0
  pandas = 2.0.0
  geopandas = 0.13.0
  rasterio = 1.3.0

Run with --package <name> to add documentation notes.
```

### Step 3: Document Package Purpose

For each key package, add documentation:

```bash
./.specify/scripts/bash/env-sync.sh --package scipy
```

**Interactive prompt**:

```
Package: scipy (1.11.0)
Current note: (none)

Enter usage note for methods section:
> Spatial interpolation of rainfall station data using ordinary kriging

Updated .env-config with package note.
```

> **Why this matters**: These notes become your methods paragraph. Instead of guessing later, you document as you go.

### Step 4: View Your Environment Configuration

Check `.env-config` to see your documented environment:

```ini
[environment]
tool = pixi
python_version = 3.11
env_name = rainfall-analysis

[packages]
scipy = 1.11.0
pandas = 2.0.0
geopandas = 0.13.0
rasterio = 1.3.0

[package_notes]
scipy = "Spatial interpolation of rainfall station data using ordinary kriging"
pandas = "Data manipulation and time series analysis of precipitation records"
geopandas = "Handling geospatial vector data for weather station locations"
rasterio = "Reading and writing precipitation raster outputs"
```

### Step 5: Export Methods Paragraph

When you're ready to write your paper:

```bash
./.specify/scripts/bash/export-methods.sh --format text
```

**Expected output**:

```
Methods Paragraph:

Analysis was conducted using Python 3.11 with the pixi package manager
for environment reproducibility. Key packages included: scipy 1.11.0
(spatial interpolation of rainfall station data using ordinary kriging),
pandas 2.0.0 (data manipulation and time series analysis of precipitation
records), geopandas 0.13.0 (handling geospatial vector data for weather
station locations), and rasterio 1.3.0 (reading and writing precipitation
raster outputs). Complete environment specifications are available in the
project repository.
```

> **Why this matters**: Your methods section is generated from actual package usage, ensuring accuracy and reproducibility.

### Troubleshooting: Package Documentation

**Problem**: Package not appearing in .env-config

**Solution**: Make sure you're in an activated environment, then run `env-sync.sh` again.

**Problem**: Methods export missing packages

**Solution**: Add documentation notes with `env-sync.sh --package <name>` for each package you want included.

---

## Next Steps

Congratulations! You've completed the res_spec quickstart. Here's where to go next:

### For Your Current Project

1. **Continue implementing**: Work through your tasks.md checklist
2. **Keep packages documented**: Run `env-sync.sh` after each `pixi add`
3. **Validate regularly**: Run `env-validate.sh` before commits

### Learn More

- **[Environment Guide](environment-guide.md)** - Deep dive into environment tool choices
- **[Pixi Workflows](pixi-workflows.md)** - Advanced pixi usage for geospatial research
- **[Troubleshooting](troubleshooting.md)** - Solutions to common issues

### For New Features

When you're ready to add another feature:

```
/speckit.specify "Your next research question"
```

The cycle continues: specify → plan → tasks → implement → document.

---

## Summary

| Step | Command | What It Does |
|------|---------|--------------|
| Initialize project | `init-project.sh` | Sets up clean project from template |
| Create specification | `/speckit.specify` | Documents what you're building |
| Generate plan | `/speckit.plan` | Designs how to build it |
| Generate tasks | `/speckit.tasks` | Creates actionable checklist |
| Implement | `/speckit.implement` | Guides you through building |
| Sync packages | `env-sync.sh` | Tracks dependencies |
| Document packages | `env-sync.sh --package` | Adds methods notes |
| Export methods | `export-methods.sh` | Generates manuscript text |

The key insight: **document as you go, not after**. By integrating documentation into your development workflow, you get accurate, complete methods sections without the retrospective struggle.

---

**Questions?** See [Troubleshooting](troubleshooting.md) or file an issue at the project repository.
