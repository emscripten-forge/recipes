#!/bin/bash

set -ex

export CFLAGS="$CFLAGS -fPIC"
export LDFLAGS="$LDFLAGS -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=1MB"

meson_setup_args=(
    -Ddocs=false
    -Dtests=false
    -Ddefault_library=static
)

meson setup builddir \
    ${meson_setup_args[@]} \
    --prefix=$PREFIX \
    --buildtype=release \
    --prefer-static \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross

meson install -C builddir
