#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

meson_config_args=(
    -Dglib=enabled
    -Dicu=enabled
    -Dfreetype=enabled
    -Dcairo=enabled
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
