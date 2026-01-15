# Air-Gapped Environment Setup

This guide covers setting up Python environments on systems without internet access (air-gapped), common in secure research facilities, HPC clusters, and field deployments.

## Overview

Air-gapped setup requires:
1. Downloading packages on a connected machine
2. Transferring packages to the air-gapped machine
3. Installing from local package cache

## Pixi Air-Gapped Setup

Pixi supports offline installation via pack/unpack.

### On Connected Machine

```bash
# Create and verify environment
cd my-project
pixi install

# Pack environment for transfer
pixi pack --output my-project-env.tar.gz

# This creates a tarball with all dependencies
ls -lh my-project-env.tar.gz
```

### Transfer

```bash
# Transfer to air-gapped machine via:
# - USB drive
# - Secure file transfer
# - Network share

scp my-project-env.tar.gz user@airgapped-host:/path/to/project/
scp pixi.toml user@airgapped-host:/path/to/project/
```

### On Air-Gapped Machine

```bash
# Unpack environment
cd /path/to/project
pixi unpack my-project-env.tar.gz

# Verify installation
pixi run python --version
pixi list
```

### Alternative: Binary Cache

For repeated setups, create a local conda channel:

```bash
# On connected machine, download packages
pixi install
# Packages are cached in ~/.cache/rattler/cache/

# Copy cache to air-gapped machine
rsync -av ~/.cache/rattler/ /shared/conda-cache/

# On air-gapped machine, configure pixi
export PIXI_CACHE_DIR=/shared/conda-cache/
pixi install
```

## Conda Air-Gapped Setup

### Option 1: Conda-Pack (Recommended)

```bash
# On connected machine
conda activate my-env
conda install -c conda-forge conda-pack

# Pack the environment
conda pack -n my-env -o my-env.tar.gz

# Transfer to air-gapped machine
scp my-env.tar.gz user@airgapped:/path/

# On air-gapped machine
mkdir -p ~/envs/my-env
tar -xzf my-env.tar.gz -C ~/envs/my-env

# Activate
source ~/envs/my-env/bin/activate

# Fix prefixes (required after unpacking)
conda-unpack
```

### Option 2: Local Channel

Create a local conda channel with all required packages:

```bash
# On connected machine

# 1. Create environment and download packages
conda create -n my-env python=3.11 numpy pandas --download-only

# 2. Find downloaded packages
ls ~/miniconda3/pkgs/

# 3. Create local channel structure
mkdir -p local-channel/linux-64
mkdir -p local-channel/noarch

# 4. Copy packages
cp ~/miniconda3/pkgs/*.tar.bz2 local-channel/linux-64/
cp ~/miniconda3/pkgs/*.conda local-channel/linux-64/

# 5. Index the channel
conda index local-channel/

# 6. Transfer local-channel directory to air-gapped machine
```

On air-gapped machine:

```bash
# Configure conda to use local channel
conda config --add channels file:///path/to/local-channel
conda config --set offline true

# Install
conda create -n my-env python=3.11 numpy pandas
```

### Option 3: Clone Existing Environment

```bash
# On connected machine with same OS/arch
conda create --name my-env python=3.11 numpy pandas
conda list --explicit > spec-file.txt

# Transfer spec-file.txt and packages

# On air-gapped machine
conda create --name my-env --file spec-file.txt --offline
```

## venv/pip Air-Gapped Setup

### Download Packages

On connected machine:

```bash
# Create requirements file
pip freeze > requirements.txt

# Download packages (including dependencies)
pip download -r requirements.txt -d ./packages/

# Or download for specific platform
pip download -r requirements.txt -d ./packages/ \
    --platform linux_x86_64 \
    --python-version 311 \
    --only-binary=:all:

# Transfer packages directory and requirements.txt
```

### Install Offline

On air-gapped machine:

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install from local packages
pip install --no-index --find-links=./packages/ -r requirements.txt
```

### Handling Packages with Binary Dependencies

Some packages (numpy, pandas, scipy) have platform-specific wheels:

```bash
# Download for multiple platforms on connected machine
pip download numpy -d ./packages/ --platform manylinux2014_x86_64
pip download numpy -d ./packages/ --platform macosx_11_0_arm64
pip download numpy -d ./packages/ --platform win_amd64
```

**Note**: For geospatial packages (GDAL, rasterio), prefer pixi or conda methods.

## Complete Air-Gapped Workflow

### Step 1: Prepare on Connected Machine

```bash
# Clone/create project
git clone https://github.com/org/research-project
cd research-project

# Initialize environment
pixi install
# OR
conda env create -f environment.yml

# Verify everything works
pixi run python -c "import numpy; import pandas; print('OK')"

# Pack for transfer
pixi pack -o project-env.tar.gz
# OR
conda pack -n my-env -o my-env.tar.gz
```

### Step 2: Transfer to Air-Gapped System

```bash
# Create transfer bundle
tar -cvzf transfer-bundle.tar.gz \
    project-env.tar.gz \
    pixi.toml \
    .env-config \
    src/ \
    notebooks/ \
    data/

# Transfer via approved method
# USB, SFTP, etc.
```

### Step 3: Setup on Air-Gapped System

```bash
# Extract bundle
tar -xzf transfer-bundle.tar.gz
cd research-project

# Unpack environment
pixi unpack project-env.tar.gz
# OR
mkdir -p ~/envs/my-env
tar -xzf my-env.tar.gz -C ~/envs/my-env
source ~/envs/my-env/bin/activate
conda-unpack

# Verify
pixi run python -c "import numpy; print('Setup complete')"
# OR
python -c "import numpy; print('Setup complete')"
```

## HPC Cluster Considerations

### Module Systems

Many HPC systems use environment modules:

```bash
# Load Python module
module load python/3.11

# Create local environment
python -m venv ~/envs/my-env
source ~/envs/my-env/bin/activate

# Install from pre-downloaded packages
pip install --no-index --find-links=/shared/packages -r requirements.txt
```

### Shared Conda Installation

If conda is available on the cluster:

```bash
# Check available conda
module avail conda

# Load and create environment
module load anaconda3
conda create -n my-env --clone /shared/envs/base-env

# Or use local channel
conda create -n my-env -c file:///shared/conda-channel python=3.11
```

### Job Script Example

```bash
#!/bin/bash
#SBATCH --job-name=analysis
#SBATCH --output=analysis_%j.out
#SBATCH --time=04:00:00
#SBATCH --mem=32G

# Load environment
source ~/envs/my-env/bin/activate

# Or with pixi
cd /path/to/project
pixi run python scripts/analysis.py
```

## Updating Air-Gapped Environments

### Version Control for Packages

Maintain a package repository:

```bash
# Structure
packages/
├── 2024-01/          # Monthly snapshots
│   ├── packages/
│   └── requirements.txt
├── 2024-02/
└── current -> 2024-02/  # Symlink to latest
```

### Incremental Updates

```bash
# On connected machine
# Download only new/updated packages
pip download -r new-requirements.txt -d ./new-packages/

# Transfer new-packages/
# On air-gapped machine
pip install --no-index --find-links=./new-packages/ new-package
```

## Security Considerations

### Package Verification

```bash
# Verify pip packages with hashes
pip download --require-hashes -r requirements.txt -d ./packages/

# Generate requirements with hashes
pip-compile --generate-hashes requirements.in
```

### Checksum Verification

```bash
# Generate checksums on connected machine
sha256sum packages/*.whl > checksums.txt

# Verify on air-gapped machine
sha256sum -c checksums.txt
```

### Audit Trail

Maintain documentation of:
- Package sources
- Download dates
- Verification steps
- Transfer approval

## Troubleshooting

### "Package not found" Errors

```bash
# Check package is in local directory
ls packages/ | grep package-name

# Check platform compatibility
pip debug --verbose  # Shows supported platforms

# Download for correct platform
pip download package-name --platform manylinux2014_x86_64
```

### Binary Compatibility Issues

```bash
# Error: ...manylinux_2_17_x86_64.whl is not supported

# Download older compatibility version
pip download numpy --platform manylinux2010_x86_64

# Or use conda/pixi (better binary handling)
```

### Missing Transitive Dependencies

```bash
# Download with all dependencies
pip download package-name -d ./packages/
# This includes all transitive dependencies

# Verify completeness
pip install --dry-run --no-index --find-links=./packages/ package-name
```
