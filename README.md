# res_spec: ef-open-science - publication meta analysis, FAIR research, open science

A template for reproducible, specification-driven PhD research workflows.

## What is res_spec?

**res_spec** helps researchers write reproducible code by combining specification-driven development with automated environment management. It integrates with Claude Code's speckit commands to ensure your research software is documented, reproducible, and ready for publication.

Instead of diving into code and hoping you can reconstruct your methods later, res_spec guides you through a structured workflow: specify what you want to do, plan how to do it, then implement with full documentation for your methods section.

## Why use res_spec?

- **Reproducibility by default**: Your environment, dependencies, and package versions are automatically tracked and documented
- **Research-focused workflows**: Speckit commands guide you from research question through implementation
- **Manuscript integration**: Export your methods section with accurate package citations and version information
- **Constitution-guided development**: A research principles document ensures your code stays focused on scientific goals
- **Specification-driven**: Write specifications before code to clarify your thinking and document your approach

## Quick Start

### Using this template for new research

1. **Create your research project from this template**
   ```bash
   # Clone the template
   git clone https://github.com/ecohydro/res-spec.git my-research-project
   cd my-research-project

   # Initialize your project (interactive prompts)
   ./.specify/scripts/bash/init-project.sh
   ```

2. **Initialize your Python environment**
   ```bash
   # With pixi (recommended for geospatial)
   ./.specify/scripts/bash/env-init.sh --tool pixi --quiet

   # Or with conda
   ./.specify/scripts/bash/env-init.sh --tool conda --quiet
   ```

3. **Start your first research feature**
   ```bash
   # In Claude Code, specify your first analysis
   /speckit.specify "Analyze rainfall patterns using kriging interpolation"
   ```

That's it! You now have a reproducible research project. See the [Quickstart Guide](docs/user/quickstart.md) for a detailed walkthrough.

## Core Workflow

### The Research Development Cycle

```
  Research Question
         |
         v
  /speckit.specify    --> Define what you want to analyze
         |
         v
  /speckit.plan       --> Design your implementation approach
         |
         v
  /speckit.implement  --> Build with environment tracking
         |
         v
  Analyze & Iterate   --> Refine your methods
```

### Daily Commands

```bash
# Validate your environment is in sync
./.specify/scripts/bash/env-validate.sh

# After installing packages, update tracking
./.specify/scripts/bash/env-sync.sh

# Document a specific package for methods section
./.specify/scripts/bash/env-sync.sh --package numpy

# Export your methods paragraph
./.specify/scripts/bash/export-methods.sh --format text
```

## What's Included

### Automatic Environment Management

- **Multi-tool support**: Works with pixi, conda, or venv based on your preference
- **Dependency tracking**: Packages and versions automatically recorded in .env-config
- **Reproducibility**: Any collaborator can recreate your exact environment
- **Methods export**: Generate accurate methods paragraphs for publications

### Research-Focused Specifications

- **Feature specifications**: Document the why before the how
- **Implementation plans**: Break research tasks into validated steps
- **Task generation**: Actionable checklists from your specifications
- **Example specs**: See `specs/` directory for real examples

### Constitution-Guided Development

Your research follows the [res_spec Constitution](.specify/memory/constitution.md) principles:

1. **Research-First Development** - Features serve scientific goals
2. **Reproducibility & Transparency** - Explicit environment documentation
3. **Documentation as Science Communication** - Explain why, not just how
4. **Incremental Implementation with Validation** - Build in validated steps
5. **Library & Method Integration** - Leverage established scientific tools

## Project Structure

```
my-research-project/
├── specs/                       # Feature specifications
├── src/                         # Reusable code modules
├── notebooks/                   # Analysis notebooks
├── docs/                        # Documentation
│   ├── user/                    # Guides for researchers
│   └── developer/               # Guides for customization
├── .specify/                    # Template configuration
│   ├── scripts/bash/            # Environment scripts
│   ├── memory/                  # Constitution
│   └── templates/               # Spec templates
└── .env-config                  # Environment tracking
```

For detailed architecture, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Common Workflows

### Starting a new analysis

```bash
# Specify what you want to analyze
/speckit.specify "Calculate evapotranspiration using Penman-Monteith equation"

# Review and approve the specification
# Then generate the implementation plan
/speckit.plan

# Generate actionable tasks
/speckit.tasks
```

### Installing scientific packages

```bash
# Install with your environment tool
pixi add scipy pandas geopandas  # or: conda install scipy pandas geopandas

# Update environment tracking
./.specify/scripts/bash/env-sync.sh

# Document a specific package with its purpose
./.specify/scripts/bash/env-sync.sh --package scipy
# Prompt: "Used for: [spatial interpolation of climate station data]"
```

### Writing your methods section

```bash
# Generate methods paragraph for your manuscript
./.specify/scripts/bash/export-methods.sh --format text

# Example output:
# "Analysis was conducted using Python 3.11 with the following packages:
#  scipy 1.11.0 (spatial interpolation of climate station data),
#  pandas 2.0.0 (data manipulation and time series analysis)..."
```

## Documentation

### For Users

- **[Quickstart Guide](docs/user/quickstart.md)** - Complete walkthrough from project creation to methods export
- **[Environment Guide](docs/user/environment-guide.md)** - Choosing between pixi, conda, and venv
- **[Pixi Workflows](docs/user/pixi-workflows.md)** - Geospatial research workflows with pixi
- **[Troubleshooting](docs/user/troubleshooting.md)** - Common issues and solutions

### For Developers

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to extend and customize res_spec
- **[Architecture](docs/developer/architecture.md)** - System design and component interaction
- **[Extending Speckit](docs/developer/extending-speckit.md)** - Adding custom commands

## Requirements

- **Claude Code** with speckit commands ([installation guide](https://claude.ai/code))
- **Python 3.9+**
- **Git**
- One of: **pixi** (recommended for geospatial), **conda**, or **venv**

## Philosophy

res_spec is designed for researchers who want:

- Reproducible computational research without extensive software engineering
- Clear documentation of methods for publications
- Structured workflows that reduce cognitive load
- Environment management that "just works"
- A system that guides rather than constrains

This isn't about writing perfect software. It's about doing rigorous science with code that you and others can understand, reproduce, and trust.

## Examples

See the `specs/` directory for example feature specifications:

- `001-python-env-management/` - Environment setup and tracking implementation
- `002-speckit-research-integration/` - Research workflow integration

## Getting Help

- **Issues**: Report bugs and request features at [GitHub Issues](https://github.com/ecohydro/res-spec/issues)
- **Documentation**: Check `docs/` directory for guides
- **Constitution**: Review research principles at [.specify/memory/constitution.md](.specify/memory/constitution.md)

## Citation

If this template supports your research, please cite:

```bibtex
@software{res_spec_template,
  title = {res\_spec: ef-open-science - publication meta analysis, FAIR research, open science},
  author = {ef-open-science},
  year = {2025},
  url = {https://github.com/ef-open-science/res-spec}
}
```

## License

MIT License - See [LICENSE](LICENSE) for details.

---

**Ready to start?** Run `./.specify/scripts/bash/init-project.sh` and then `/speckit.specify` with your first research question.
