#!/bin/bash

echo "PYTHON"

rm -r -f branding

export CFLAGS="$CFLAGS -Wno-return-type -Wno-implicit-function-declaration -msimd128 -fwasm-exceptions -s SUPPORT_LONGJMP"

if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    export MESON_CROSS_FILE=$RECIPE_DIR/emscripten.meson.cross-wasm32
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    export MESON_CROSS_FILE=$RECIPE_DIR/emscripten.meson.cross-wasm64
  # replace 
else 
  echo "Unsupported target_platform: $target_platform"
  exit 1
fi


export LDFLAGS="$LDFLAGS  -fwasm-exceptions -s SUPPORT_LONGJMP"

cp $RECIPE_DIR/config/config.h.in  numpy/_core/config.h.in
# 

# otherwise "cython" is not properly executable
echo "add shebang to cython file"
sed -i '1i#!/usr/bin/env python' $BUILD_PREFIX/bin/cython



# replace -fexceptions with -fwasm-exceptions in numpy/_core
sed -i 's/-fexceptions/-fwasm-exceptions/g' numpy/_core/meson.build


MESON_ARGS="-Dhave_backtrace=false" ${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="-Dallow-noblas=true" \
    -Csetup-args="--cross-file=$MESON_CROSS_FILE"
