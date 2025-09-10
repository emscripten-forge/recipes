#!/bin/bash

set -ex

# Set WebAssembly-specific flags for C extensions
export CFLAGS="$CFLAGS -I$PREFIX/include/python$PY_VER -I$PREFIX/include"
export CXXFLAGS="$CXXFLAGS -I$PREFIX/include/python$PY_VER -I$PREFIX/include"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"

# Enable PYODIDE mode for WebAssembly-specific handling in galpy
export PYODIDE=1

# Disable OpenMP for WebAssembly compatibility
export GALPY_COMPILE_NO_OPENMP=1

# For now, disable C extensions until GSL is available for emscripten
# This allows galpy to install and work with pure Python implementations
export GALPY_COMPILE_NO_EXT=1

# Install with verbose output for debugging
${PYTHON} -m pip install . --no-deps --verbose