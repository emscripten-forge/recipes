#!/bin/bash

export CFLAGS="$CFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -Wno-implicit-function-declaration -fwasm-exceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fwasm-exceptions"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fwasm-exceptions"

# otherwise "cython" is not properly executable
echo "add shebang to cython file"
sed -i '1i#!/usr/bin/env python' $BUILD_PREFIX/bin/cython

cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
echo "python = '${PYTHON}'" >> $SRC_DIR/emscripten.meson.cross

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"
