#!/bin/bash
export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python3.10/site-packages/numpy/core/include/"
${PYTHON} -m pip  install .
