#!/bin/bash

export LDFLAGS="$(LDFLAGS) -sUSE_FREETYPE=1 -sUSE_PTHREADS=0"

# Disable pthreads
sed -i '292,296d' meson.build

meson_setup_args=(
    -Dtests=disabled
    -Ddefault_library=static
    -Dtools=disabled
)

meson setup builddir \
    ${meson_setup_args[@]} \
    --prefix=$PREFIX \
    --buildtype=release \
    --prefer-static \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross

meson install -C builddir
