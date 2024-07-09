#!/bin/bash

echo "called with args: $@"

set -e

$BUILD_PREFIX/bin/python3 $RECIPE_DIR/py_wrapper.py $BUILD_PREFIX/opt/emsdk/upstream/emscripten/emcc  "$@"
exit $?