#!/bin/bash
export CFLAGS="${CFLAGS} -DHAVE_UINT32_T -I$BUILD_PREFIX/lib/python3.11/site-packages/numpy/core/include/"
${PYTHON} -m pip install .

