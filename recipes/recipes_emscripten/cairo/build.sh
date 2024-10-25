#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

export CFLAGS="${CFLAGS} -DCAIRO_NO_MUTEX=1"
export LDFLAGS="${LDFLAGS} -lz"

meson_config_args=(
    -Dfontconfig=enabled
    -Dfreetype=enabled
    -Dglib=enabled
    -Dpng=disabled
    -Dxlib=disabled
    -Dxlib-xcb=disabled
    -Dxcb=disabled
    -Dspectre=disabled
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
