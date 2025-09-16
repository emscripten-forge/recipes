#!/bin/bash

set -ex

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="-I$PREFIX/include $CPPFLAGS"
export LDFLAGS="-L$PREFIX/lib $LDFLAGS"

# Copy and set up meson cross file
cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
echo "python = '${PYTHON}'" >> $SRC_DIR/emscripten.meson.cross

# Build the package using pip with meson-python backend
$PYTHON -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"