# Python Environment Management Guide

This guide helps researchers choose and manage Python environments for reproducible research workflows.

## Quick Start

```bash
# Initialize a new environment (interactive)
./.specify/scripts/bash/env-init.sh

# Or use specific options
./.specify/scripts/bash/env-init.sh --tool pixi --quiet

# Reproduce from existing configuration
./.specify/scripts/bash/env-init.sh --from-config
```

## Choosing an Environment Tool

### Decision Tree

```
Need geospatial packages (GDAL, PROJ, rasterio)?
├── Yes → Use PIXI or CONDA (binary dependencies handled)
└── No
    ├── Want fastest setup? → Use PIXI
    ├── Familiar with conda? → Use CONDA
    └── Minimal dependencies? → Use VENV
```

### Tool Comparison

| Feature | Pixi | Conda | venv |
|---------|------|-------|------|
| **Speed** | Fast (Rust-based) | Slow-Medium | Fast |
| **Binary packages** | Excellent | Excellent | Limited |
| **Geospatial support** | Excellent | Excellent | Difficult |
| **Cross-platform** | Excellent | Good | Good |
| **No activation needed** | Yes | No | No |
| **Lockfile** | Yes | No (env export) | No (pip freeze) |
| **Learning curve** | Low | Medium | Very Low |
| **Ecosystem maturity** | New | Mature | Mature |

## Pixi (Recommended)

Pixi is a modern package manager built on the conda-forge ecosystem. It provides fast, reproducible environments with excellent support for geospatial packages.

### Why Pixi?

1. **Speed**: Written in Rust, parallel downloads, efficient solving
2. **Reproducibility**: Automatic lockfiles ensure exact reproducibility
3. **Simplicity**: No activation required - `pixi run python` just works
4. **Cross-platform**: Single `pixi.toml` works on Linux, macOS, Windows
5. **Geospatial**: Direct access to conda-forge (GDAL, PROJ, rasterio work out of box)

### Basic Workflow

```bash
# Initialize project
pixi init

# Add dependencies
pixi add numpy pandas matplotlib
pixi add geopandas rasterio  # Geospatial packages work seamlessly

# Run commands
pixi run python my_script.py
pixi run jupyter lab

# Enter shell (if you prefer activation)
pixi shell
```

### Project Configuration (pixi.toml)

```toml
[project]
name = "my-research"
channels = ["conda-forge"]
platforms = ["linux-64", "osx-arm64", "osx-64", "win-64"]

[dependencies]
python = "3.11.*"
numpy = ">=1.24"
pandas = ">=2.0"
geopandas = ">=0.14"
rasterio = ">=1.3"

[tasks]
lab = "jupyter lab"
test = "pytest tests/"
```

### When to Use Pixi

- New projects starting fresh
- Geospatial/scientific computing projects
- Cross-platform collaboration
- When you want fast environment setup
- When reproducibility is critical

## Conda/Mamba

Conda is the traditional choice for scientific Python. Mamba is a faster drop-in replacement.

### Basic Workflow

```bash
# Create environment from file
conda env create -f environment.yml
# or faster with mamba
mamba env create -f environment.yml

# Activate
conda activate my-env

# Install packages
conda install numpy pandas
conda install -c conda-forge geopandas

# Export for reproducibility
conda env export > environment.yml
```

### Project Configuration (environment.yml)

```yaml
name: my-research
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  - numpy>=1.24
  - pandas>=2.0
  - geopandas>=0.14
  - pip
  - pip:
    - some-pip-only-package
```

### When to Use Conda

- Existing conda workflows
- Shared environments across projects
- When colleagues use conda
- Complex dependency requirements
- When you need environment cloning

## venv (Python Built-in)

Python's built-in virtual environment tool. Simple but limited.

### Basic Workflow

```bash
# Create environment
python3 -m venv venv

# Activate
source venv/bin/activate  # Linux/macOS
.\venv\Scripts\activate   # Windows

# Install packages
pip install numpy pandas matplotlib

# Export dependencies
pip freeze > requirements.txt

# Install from requirements
pip install -r requirements.txt
```

### Project Configuration (requirements.txt)

```
numpy>=1.24.0
pandas>=2.0.0
matplotlib>=3.7.0
scipy>=1.11.0
```

### When to Use venv

- Simple Python-only projects
- Quick prototyping
- When conda/pixi aren't available
- Minimal dependency footprint
- Teaching/learning environments

### Limitations

- No binary package management
- Geospatial packages often fail (GDAL, PROJ)
- Platform-specific issues with compiled extensions
- No automatic lockfile

## Environment Files

### .env-config

Our central configuration file that tracks your environment setup:

```ini
[environment]
tool = pixi
python_version = 3.11
env_name = my-research
created = 2024-01-15
platform = linux-x64

[packages]
numpy = 1.26.0
pandas = 2.1.0

[package_notes]
numpy = "Used for numerical computations in hydrological modeling"
pandas = "Data manipulation for timeseries analysis"
```

### Using Environment Scripts

```bash
# Initialize environment
./.specify/scripts/bash/env-init.sh

# Sync dependencies after changes
./.specify/scripts/bash/env-sync.sh

# Validate environment
./.specify/scripts/bash/env-validate.sh

# Document a package for manuscripts
./.specify/scripts/bash/env-sync.sh --package numpy
```

## Best Practices

### For Reproducibility

1. **Pin versions** in production/publication code
2. **Use lockfiles** (pixi.lock, pip freeze output)
3. **Document environment** in .env-config with package notes
4. **Test on clean environment** before sharing
5. **Include platform info** when reporting issues

### For Collaboration

1. **Choose one tool** per project
2. **Commit configuration files** (pixi.toml, environment.yml, requirements.txt)
3. **Don't commit lockfiles** unless exact reproducibility needed
4. **Document activation steps** in README
5. **Use `--from-config`** to reproduce teammate's environment

### For Performance

1. **Use pixi or mamba** for faster package solving
2. **Minimize dependencies** - only install what you need
3. **Use conda-forge channel** for consistent builds
4. **Clean unused packages** periodically

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.

## Further Reading

- [Pixi Documentation](https://prefix.dev/docs/pixi/overview)
- [Conda Documentation](https://docs.conda.io/)
- [Python venv Documentation](https://docs.python.org/3/library/venv.html)
- [conda-forge](https://conda-forge.org/)
