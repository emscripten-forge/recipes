#!/bin/bash
export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python$PY_VER/site-packages/numpy/core/include/"
${PYTHON} -m pip  install .
