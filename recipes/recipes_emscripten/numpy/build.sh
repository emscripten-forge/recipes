#!/bin/bash

echo "PYTHON"

rm -r -f branding

export CFLAGS="$CFLAGS -Wno-return-type -Wno-implicit-function-declaration"
export MESON_CROSS_FILE=$RECIPE_DIR/emscripten.meson.cross
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -sEXPORTED_FUNCTIONS=['_init_numpy']"



cp $RECIPE_DIR/config/config.h.in  numpy/_core/config.h.in
# 

# otherwise "cython" is not properly executable
echo "add shebang to cython file"
sed -i '1i#!/usr/bin/env python' $BUILD_PREFIX/bin/cython


MESON_ARGS="-Dhave_backtrace=false" ${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="-Dallow-noblas=true" \
    -Csetup-args="--cross-file=$MESON_CROSS_FILE"
