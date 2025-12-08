#!/bin/bash


DISABLED=-Wno-incompatible-function-pointer-types

export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python$PY_VER/site-packages/numpy/_core/include/"

${PYTHON}  -m pip install . --no-deps  -vvv
