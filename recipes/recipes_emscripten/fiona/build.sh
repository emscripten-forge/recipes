#!/bin/bash

# Emscripten flags
export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# Point Fiona to GDAL (this is critical)
export GDAL_VERSION=$(gdal-config --version || echo "unknown")
echo "******"
echo $GDAL_VERSION
echo "******"
export GDAL_INCLUDE_PATH=$PREFIX/include
export GDAL_LIBRARY_PATH=$PREFIX/lib

# Sometimes needed to bypass config detection
export GDAL_CONFIG=/bin/false

# Install
${PYTHON} -m pip install . --no-deps --no-build-isolation -vv
