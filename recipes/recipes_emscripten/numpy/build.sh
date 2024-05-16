#!/bin/bash

echo "PYTHON"

rm -r -f branding

export CFLAGS="$CFLAGS -Wno-return-type -Wno-implicit-function-declaration"
export MESON_CROSS_FILE=$RECIPE_DIR/emscripten.meson.cross

export LDFLAGS="$LDFLAGS -sWASM_BIGINT -Wno-map-unrecognized-libraries"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="-Dallow-noblas=true" \
    -Csetup-args="--cross-file=$MESON_CROSS_FILE"
