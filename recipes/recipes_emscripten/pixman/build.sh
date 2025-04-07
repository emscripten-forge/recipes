#!/bin/bash

set -eux

meson_config_args=(
    -Dgtk=disabled
    -Dlibdir=lib
    -Ddemos=disabled
    -Dtests=disabled
)

meson setup builddir \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --default-library=static \
    --prefix=$PREFIX \
    --wrap-mode=nofallback \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross

ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}
