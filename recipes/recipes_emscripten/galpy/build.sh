#!/bin/bash

set -ex

# Set WebAssembly-specific flags for C extensions
export CFLAGS="$CFLAGS -I$PREFIX/include/python$PY_VER"
export CXXFLAGS="$CXXFLAGS -I$PREFIX/include/python$PY_VER"

# Disable OpenMP if galpy tries to use it (common issue with WASM)
export GALPY_COMPILE_NO_OPENMP=1

# Install with verbose output for debugging
${PYTHON} -m pip install . --no-deps --verbose