#!/bin/bash

set -ex

# Set WebAssembly-specific flags for C extensions
export CFLAGS="$CFLAGS -I$PREFIX/include/python$PY_VER"
export CXXFLAGS="$CXXFLAGS -I$PREFIX/include/python$PY_VER"

# Enable PYODIDE mode for WebAssembly-specific handling in galpy
export PYODIDE=1

# This will automatically disable OpenMP and set GSL version for WASM builds
# GALPY_COMPILE_NO_OPENMP is redundant when PYODIDE=1 but kept for clarity
export GALPY_COMPILE_NO_OPENMP=1

# Install with verbose output for debugging
${PYTHON} -m pip install . --no-deps --verbose