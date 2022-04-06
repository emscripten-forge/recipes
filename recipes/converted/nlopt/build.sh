#!/bin/bash
export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -std=c++11  -s LZ4=1 -s SIDE_MODULE=1"
export CFLAGS="-DHAVE_UINT32_T -I$BUILD_PREFIX/lib/python3.10/site-packages/numpy/core/include/"
LDFLAGS="$LDFLAGS" CFLAGS="$CFLAGS" python -m pip  install .