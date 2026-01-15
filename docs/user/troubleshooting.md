# Environment Troubleshooting Guide

Common issues and solutions for Python environment management.

## Quick Diagnostics

Run the validation script first:

```bash
./.specify/scripts/bash/env-validate.sh
```

This will identify most common issues and suggest fixes.

## General Issues

### "Command not found" Errors

**Problem**: `pixi`, `conda`, or `python` not found

**Solutions**:

```bash
# Check if installed
which pixi
which conda
which python3

# Pixi: Add to PATH
export PATH="$HOME/.pixi/bin:$PATH"

# Conda: Initialize shell
conda init bash  # or zsh
source ~/.bashrc

# Verify installation
pixi --version
conda --version
python3 --version
```

### Environment Not Activating

**Problem**: Changes don't persist, wrong Python version

**Solutions**:

```bash
# Pixi (doesn't need activation)
pixi run python --version  # Run directly
pixi shell                 # Or enter shell

# Conda
conda activate my-env
# If "conda activate" doesn't work:
source $(conda info --base)/etc/profile.d/conda.sh
conda activate my-env

# venv
source venv/bin/activate
# Verify activation
which python  # Should point to venv
```

### Slow Package Installation

**Problem**: Conda takes forever to solve environment

**Solutions**:

```bash
# Use mamba instead of conda
conda install -n base -c conda-forge mamba
mamba install package-name

# Or switch to pixi (much faster)
pixi add package-name

# For conda, try stricter channel priority
conda config --set channel_priority strict
```

## Pixi-Specific Issues

### "Failed to solve environment"

**Problem**: Pixi can't find compatible package versions

**Solutions**:

```bash
# Check available versions
pixi search package-name

# Try with version range instead of exact
# In pixi.toml, change:
#   package = "1.2.3"
# To:
#   package = ">=1.2"

# Update pixi itself
pixi self-update

# Clean and retry
rm -rf .pixi pixi.lock
pixi install
```

### Platform Compatibility

**Problem**: Package not available for your platform

**Solutions**:

```toml
# In pixi.toml, check platforms
[project]
platforms = ["linux-64", "osx-arm64", "osx-64", "win-64"]

# Remove unavailable platform
platforms = ["linux-64", "osx-64"]  # If osx-arm64 causes issues

# For macOS ARM, try x64 packages via Rosetta
pixi add --platform osx-64 problematic-package
```

### Pixi Lock Conflicts

**Problem**: `pixi.lock` won't update or conflicts

**Solutions**:

```bash
# Delete lock and regenerate
rm pixi.lock
pixi install

# If collaborator has different lock
git checkout --theirs pixi.lock
pixi install
```

## Conda-Specific Issues

### Channel Conflicts

**Problem**: Packages from different channels conflict

**Solutions**:

```bash
# Set strict channel priority
conda config --set channel_priority strict

# In environment.yml, order channels properly
channels:
  - conda-forge  # First priority
  - defaults

# Or use only conda-forge
channels:
  - conda-forge
```

### "Solving environment: failed"

**Problem**: Conda can't resolve dependencies

**Solutions**:

```bash
# Use mamba for better solving
mamba env create -f environment.yml

# Create fresh environment
conda env remove -n my-env
mamba env create -f environment.yml

# Simplify environment.yml
# Remove version pins, let solver find compatible versions
dependencies:
  - python=3.11
  - numpy   # No version pin
  - pandas  # No version pin
```

### Environment Export Issues

**Problem**: Exported environment won't recreate

**Solutions**:

```bash
# Export without build strings (more portable)
conda env export --no-builds > environment.yml

# Or export only explicitly installed packages
conda env export --from-history > environment.yml

# Manual cleanup: Remove platform-specific packages
# Edit environment.yml to remove packages like:
#   - libgcc-ng (Linux only)
#   - vs2015_runtime (Windows only)
```

## venv/pip-Specific Issues

### "Could not build wheels"

**Problem**: pip can't compile package from source

**Solutions**:

```bash
# Install build dependencies first
# Ubuntu/Debian
sudo apt install build-essential python3-dev

# macOS (install Xcode command line tools)
xcode-select --install

# For specific packages (GDAL example)
sudo apt install libgdal-dev
export CPLUS_INCLUDE_PATH=/usr/include/gdal
export C_INCLUDE_PATH=/usr/include/gdal
pip install gdal==$(gdal-config --version)
```

**Better solution**: Use pixi or conda for packages with binary dependencies.

### Geospatial Package Failures

**Problem**: GDAL, rasterio, fiona won't install with pip

**Solutions**:

This is why we recommend pixi or conda for geospatial work. If you must use pip:

```bash
# Ubuntu/Debian
sudo apt install gdal-bin libgdal-dev
sudo apt install libproj-dev proj-data proj-bin
sudo apt install libgeos-dev

# macOS with Homebrew
brew install gdal proj geos

# Then pip install
pip install gdal==$(gdal-config --version)
pip install rasterio fiona geopandas
```

### Version Conflicts

**Problem**: Package A requires numpy<2.0, Package B requires numpy>=2.0

**Solutions**:

```bash
# Check what's conflicting
pip check

# Install in order (let pip backtrack)
pip install package-a
pip install package-b  # May downgrade dependencies

# Or use pip-tools for better resolution
pip install pip-tools
pip-compile requirements.in
pip-sync requirements.txt
```

## Cross-Platform Issues

### Windows Path Issues

**Problem**: Scripts or paths don't work on Windows

**Solutions**:

```python
# In Python, use pathlib for cross-platform paths
from pathlib import Path

data_dir = Path("data") / "raw" / "file.csv"  # Works on all platforms

# Or os.path.join
import os
data_dir = os.path.join("data", "raw", "file.csv")
```

### Line Ending Issues

**Problem**: Scripts fail with `\r` errors on Linux/Mac after editing on Windows

**Solutions**:

```bash
# Configure git to handle line endings
git config --global core.autocrlf input  # Linux/Mac
git config --global core.autocrlf true   # Windows

# Fix existing files
dos2unix script.sh

# Or in vim
:set ff=unix
:wq
```

### Shell Script Compatibility

**Problem**: Bash scripts fail on Windows

**Solutions**:

- Use Git Bash on Windows
- Use WSL (Windows Subsystem for Linux)
- Convert scripts to Python for cross-platform

```bash
# In script, check for Windows
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows-specific handling
fi
```

## Jupyter-Specific Issues

### Wrong Kernel

**Problem**: Jupyter uses wrong Python environment

**Solutions**:

```bash
# Register kernel explicitly
# Pixi
pixi run python -m ipykernel install --user --name=my-env

# Conda (activate first)
conda activate my-env
python -m ipykernel install --user --name=my-env

# venv (activate first)
source venv/bin/activate
pip install ipykernel
python -m ipykernel install --user --name=my-env

# List kernels
jupyter kernelspec list

# Remove old kernels
jupyter kernelspec remove old-kernel-name
```

### Import Errors in Notebook

**Problem**: Package installed but can't import in notebook

**Solutions**:

```python
# Check which Python the notebook is using
import sys
print(sys.executable)
print(sys.path)

# Should match your environment
# If not, restart kernel and select correct one
```

## Recovery Procedures

### Complete Reset (Nuclear Option)

When nothing else works:

```bash
# Pixi
rm -rf .pixi pixi.lock
pixi install

# Conda
conda env remove -n my-env
conda clean --all
conda env create -f environment.yml

# venv
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Restore from Config

Use our scripts to restore:

```bash
# Validate first
./.specify/scripts/bash/env-validate.sh

# Attempt automatic fix
./.specify/scripts/bash/env-validate.sh --fix

# Or reinitialize from config
./.specify/scripts/bash/env-init.sh --from-config
```

## Getting Help

### Information to Include

When asking for help, provide:

```bash
# System info
uname -a
python3 --version

# Environment tool versions
pixi --version
conda --version

# Environment validation
./.specify/scripts/bash/env-validate.sh --json

# Error output (full traceback)
```

### Resources

- Pixi: https://github.com/prefix-dev/pixi/issues
- Conda: https://github.com/conda/conda/issues
- conda-forge: https://github.com/conda-forge/staged-recipes/issues
- Package-specific issues: Check package's GitHub repository
