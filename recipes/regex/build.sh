#!/bin/bash
ls $BUILD_PREFIX/venv/bin/
echo "PYTHON"


# export EMCC_DEBUG=1
export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -std=c++14  -s LZ4=1 -s SIDE_MODULE=1"
# export LDFLAGS="-s SIDE_MODULE=1"

LDFLAGS="$LDFLAGS"  python setup.py install