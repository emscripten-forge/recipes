#!/bin/bash

export MESON_CROSS_FILE=$RECIPE_DIR/emscripten.meson.cross

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$MESON_CROSS_FILE"
