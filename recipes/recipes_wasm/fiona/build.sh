#!/bin/bash
set -e

# include paths
export CFLAGS="${CFLAGS:-} -I$PREFIX/include -fPIC"

# link paths + GDAL (critical)
export LDFLAGS="${LDFLAGS:-} -L$PREFIX/lib -lgdal -fPIC"

# Fiona-specific GDAL hints
export GDAL_INCLUDE_PATH="$PREFIX/include"
export GDAL_LIBRARY_PATH="$PREFIX/lib"

# DO NOT disable gdal-config
# export GDAL_CONFIG=/bin/false  <-- remove this

${PYTHON} -m pip install . --no-deps --no-build-isolation -vv
