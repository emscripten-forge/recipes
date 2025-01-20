#!/bin/bash

# Note: the include folder is moved to `$BUILD_PREFIX` by the cross-python activation script
export NUMPY_INCLUDE_DIR="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"

export DISABLE_NUMCODECS_SSE2=1
export DISABLE_NUMCODECS_AVX2=1


export CFLAGS="$CFLAGS -I$NUMPY_INCLUDE_DIR"
${PYTHON} -m pip install .
