#!/bin/bash

set -ex

meson_config_args=(
    -Dintrospection=disabled # requires gobject-introspection as run-time dep
    -Dfontconfig=enabled
    -Dfreetype=enabled
    -Dglib=enabled
    -Dcairo=enabled
    -Dharfbuzz=enabled
    -Dfribidi=enabled
    -Dlibpng=enabled
    -Dtests=disabled
)

meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --default-library=static \
    --prefer-static \
    --prefix=$PREFIX \
    -Dlibdir=lib \
    --wrap-mode=nofallback \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross

ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}