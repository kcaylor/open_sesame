# Pixi Workflows for Geospatial Research

This guide covers Pixi-specific workflows optimized for geospatial and environmental research.

## Why Pixi for Geospatial?

Geospatial Python packages have notoriously complex dependencies:

- **GDAL**: Requires system libraries, version-sensitive
- **PROJ**: Coordinate transformation library
- **GEOS**: Geometry engine for spatial operations
- **HDF5/NetCDF**: Scientific data formats

Pixi handles these seamlessly by using conda-forge's pre-built binaries.

## Setting Up a Geospatial Project

### Initial Setup

```bash
# Create new project
mkdir my-geospatial-project
cd my-geospatial-project

# Initialize with pixi
pixi init

# Add geospatial stack
pixi add python=3.11 \
    numpy pandas scipy matplotlib \
    geopandas rasterio xarray rioxarray \
    shapely pyproj fiona \
    netcdf4 h5py zarr
```

### Recommended pixi.toml for Geospatial

```toml
[project]
name = "geospatial-research"
version = "0.1.0"
description = "Geospatial analysis project"
channels = ["conda-forge"]
platforms = ["linux-64", "osx-arm64", "osx-64", "win-64"]

[dependencies]
# Core Python
python = "3.11.*"

# Numerical Computing
numpy = ">=1.24"
scipy = ">=1.11"
pandas = ">=2.0"

# Visualization
matplotlib = ">=3.7"
seaborn = ">=0.12"
cartopy = ">=0.22"  # Map projections

# Geospatial Vector
geopandas = ">=0.14"
shapely = ">=2.0"
fiona = ">=1.9"
pyproj = ">=3.6"

# Geospatial Raster
rasterio = ">=1.3"
xarray = ">=2023.10"
rioxarray = ">=0.15"

# Scientific Data Formats
netcdf4 = ">=1.6"
h5py = ">=3.9"
zarr = ">=2.16"

# Jupyter
jupyterlab = ">=4.0"
ipykernel = ">=6.0"
ipywidgets = ">=8.0"

# Interactive Maps (optional)
# folium = ">=0.14"
# leafmap = ">=0.27"

[tasks]
lab = "jupyter lab"
notebook = "jupyter notebook"

[feature.dev.dependencies]
pytest = ">=7.0"
pytest-cov = ">=4.0"
black = ">=23.0"
ruff = ">=0.1"

[environments]
default = ["default"]
dev = ["default", "dev"]
```

## Common Workflows

### Working with Raster Data

```python
# In your Python code or notebook
import rasterio
import xarray as xr
import rioxarray  # Extends xarray with rasterio functionality

# Open raster with rasterio
with rasterio.open("dem.tif") as src:
    data = src.read(1)
    profile = src.profile

# Or use xarray for multi-dimensional data
ds = xr.open_dataset("climate_data.nc")
ds = xr.open_dataarray("dem.tif", engine="rasterio")

# Save with CRS preserved
ds.rio.to_raster("output.tif")
```

### Working with Vector Data

```python
import geopandas as gpd
from shapely.geometry import Point, Polygon

# Read vector data
gdf = gpd.read_file("watersheds.shp")

# Coordinate operations (handled by pyproj)
gdf_utm = gdf.to_crs("EPSG:32610")

# Spatial operations (handled by shapely/geos)
buffered = gdf.buffer(1000)  # 1km buffer
intersected = gpd.overlay(gdf1, gdf2, how="intersection")

# Save
gdf.to_file("output.gpkg", driver="GPKG")
```

### Working with NetCDF/Climate Data

```python
import xarray as xr
import numpy as np

# Open NetCDF
ds = xr.open_dataset("climate.nc")

# Select and process
temp = ds["temperature"].sel(time="2020")
mean_temp = temp.mean(dim="time")

# Write NetCDF
mean_temp.to_netcdf("mean_temperature.nc")

# Write to Zarr (better for cloud/parallel)
ds.to_zarr("climate.zarr")
```

## Platform-Specific Notes

### macOS (Apple Silicon / M1/M2/M3)

Pixi handles ARM64 architecture automatically:

```toml
platforms = ["osx-arm64", "osx-64", "linux-64", "win-64"]
```

Most geospatial packages work out of the box. If you encounter issues:

```bash
# Force x86 emulation (last resort)
pixi add --platform osx-64 problematic-package
```

### Windows

GDAL and related libraries work well via conda-forge:

```bash
# No special configuration needed
pixi add gdal rasterio geopandas
```

For WSL users, use the Linux platform.

### Linux (HPC Clusters)

If pixi isn't available on your cluster:

```bash
# Install pixi in user space
curl -fsSL https://pixi.sh/install.sh | bash

# Or use the standalone binary
curl -fsSL https://github.com/prefix-dev/pixi/releases/latest/download/pixi-x86_64-unknown-linux-musl.tar.gz | tar xz
./pixi install
```

## Pixi Tasks for Research

Define common research tasks in pixi.toml:

```toml
[tasks]
# Start Jupyter
lab = "jupyter lab"

# Run analysis notebooks
analyze = "jupyter nbconvert --execute --inplace notebooks/*.ipynb"

# Generate figures
figures = "python scripts/generate_figures.py"

# Run tests
test = "pytest tests/ -v"

# Quality checks
lint = "ruff check src/"
format = "black src/ notebooks/"

# Full pipeline
pipeline = { depends_on = ["test", "analyze", "figures"] }
```

Usage:

```bash
pixi run lab          # Start Jupyter Lab
pixi run analyze      # Execute all notebooks
pixi run pipeline     # Run full research pipeline
```

## Handling GDAL Issues

### Version Conflicts

If you see GDAL version warnings:

```bash
# Pin GDAL version explicitly
pixi add gdal=3.7

# Or let pixi solve (usually works)
pixi add gdal
```

### Missing Drivers

Check available drivers:

```python
from osgeo import gdal
print(gdal.GetDriverCount())
for i in range(gdal.GetDriverCount()):
    print(gdal.GetDriver(i).ShortName)
```

Most drivers are included in conda-forge builds.

### PROJ Database

PROJ needs its database for coordinate transformations:

```python
import pyproj
print(pyproj.datadir.get_data_dir())
```

Pixi/conda handles this automatically. If issues arise:

```bash
pixi add proj-data
```

## Reproducibility Tips

### Lock Your Environment

```bash
# pixi.lock is created automatically
git add pixi.lock  # Include in version control for exact reproducibility
```

### Document Data Sources

In your notebooks or scripts:

```python
"""
Data Sources:
- DEM: USGS 3DEP 1/3 arc-second (downloaded 2024-01-15)
- Climate: ERA5 hourly data (1979-2023)
- Watersheds: HUC12 boundaries from USGS WBD
"""
```

### Environment Validation

Before running analyses:

```bash
./.specify/scripts/bash/env-validate.sh
```

### Export for Publication

When publishing:

```bash
# Include these in your data/code repository
pixi.toml        # Human-readable dependencies
pixi.lock        # Exact versions for reproduction
.env-config      # Package documentation for methods section
```

## Integration with Research Tools

### Jupyter Lab Extensions

```bash
pixi add jupyterlab-git    # Git integration
pixi add jupyterlab-lsp    # Language server
pixi add ipympl            # Interactive matplotlib
```

### Parallel Processing

```bash
pixi add dask distributed  # Parallel computing
pixi add joblib            # Simple parallelization
```

### Machine Learning (if needed)

```bash
pixi add scikit-learn
pixi add xgboost lightgbm  # Gradient boosting
# For deep learning, consider separate environment
```

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues.

### Quick Fixes

```bash
# Clean and reinstall
rm -rf .pixi pixi.lock
pixi install

# Update all packages
pixi update

# Check for conflicts
pixi list
```
