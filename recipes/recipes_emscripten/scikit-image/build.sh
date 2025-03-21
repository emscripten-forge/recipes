#!/bin/bash



export CFLAGS="$CFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -Wno-implicit-function-declaration -fexceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"



cp $RECIPE_DIR/patches/_base.py $SRC_DIR/sklearn/datasets/_base.py

# otherwise "cython" is not properly executable
echo "add shebang to cython file"
sed -i '1i#!/usr/bin/env python' $BUILD_PREFIX/bin/cython




cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
echo "python = '${PYTHON}'" >> $SRC_DIR/emscripten.meson.cross

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"
