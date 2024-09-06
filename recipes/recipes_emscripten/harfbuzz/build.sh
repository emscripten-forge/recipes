#!/bin/bash

set -ex

meson_config_args=(
    -Dglib=enabled
    -Dicu=enabled
    -Dfreetype=enabled
    -Dcairo=disabled
    -Dchafa=disabled
    -Dgraphite=enabled
    -Dintrospection=disabled # requires gobject-introspection as run-time dep
    -Dtests=disabled
    -Dutilities=disabled
    -Dlibdir=lib
)

# Default library needs to be shared or both to enable introspection
meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --default-library=static \
    --prefix=$PREFIX \
    --wrap-mode=nofallback \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross
ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}
