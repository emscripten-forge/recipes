#!/bin/bash
set -e

# match rasterio exactly
embuilder build libjpeg --pic

export EMSCRIPTEN_SYSROOT=$(em-config CACHE)/sysroot
export EMSCRIPTEN_INCLUDE=$EMSCRIPTEN_SYSROOT/include
export EMSCRIPTEN_LIB=$EMSCRIPTEN_SYSROOT/lib/wasm32-emscripten/pic

# include paths
export CFLAGS="$CFLAGS -I${EMSCRIPTEN_INCLUDE} -I$PREFIX/include -fPIC"

# link paths + GDAL (critical)
export LDFLAGS="$LDFLAGS -L${EMSCRIPTEN_LIB} -L$PREFIX/lib -lgdal -fPIC"

# Fiona-specific GDAL hints
export GDAL_INCLUDE_PATH="$PREFIX/include"
export GDAL_LIBRARY_PATH="$PREFIX/lib"

# DO NOT disable gdal-config
# export GDAL_CONFIG=/bin/false  <-- remove this

${PYTHON} -m pip install . --no-deps --no-build-isolation -vv