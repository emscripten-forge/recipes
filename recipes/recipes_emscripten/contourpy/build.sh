#!/bin/bash

cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
echo "python = '${PYTHON}'" >> $SRC_DIR/emscripten.meson.cross

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"
