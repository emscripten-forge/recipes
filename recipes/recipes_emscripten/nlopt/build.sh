#!/bin/bash

NUMPY_INCLUDE_DIR="$PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include/"
export CFLAGS="${CFLAGS} -fPIC -DHAVE_UINT32_T -I${NUMPY_INCLUDE_DIR}"
export CXXFLAGS="${CXXFLAGS} -fPIC -I${NUMPY_INCLUDE_DIR}"

${PYTHON} -m pip install .

