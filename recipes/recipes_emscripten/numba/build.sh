#!/bin/bash
set -euxo pipefail

export PYTHONNOUSERSITE=1
export NUMBA_DISABLE_OPENMP=1
export NUMBA_DISABLE_TBB=1

# cross-python relocates target NumPy headers into BUILD_PREFIX so native
# setup.py can read them while Emscripten compiles extensions for wasm32.
export NUMBA_NUMPY_INCLUDE="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"

${PYTHON} -m pip install . --no-deps -vvv
