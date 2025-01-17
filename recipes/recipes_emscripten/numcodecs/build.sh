#!/bin/bash

# Note: the include folder is moved to `$BUILD_PREFIX` by the cross-python activation script
export NUMPY_INCLUDE_DIR="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"


export CFLAGS="$CFLAGS -I$NUMPY_INCLUDE_DIR"
${PYTHON} -m pip install .
