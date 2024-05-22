#!/bin/bash

set -ex

# export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
# export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

meson_config_args=(
    -Dfontconfig=enabled
    -Dfreetype=enabled
    -Dglib=enabled
    -Dxlib=disabled
    -Dxlib-xcb=disabled
    -Dxcb=disabled
    -Dspectre=disabled
    -Dtests=disabled
)

# if test $(uname) == Darwin ; then
#     meson_config_args+=(
#         -Dxlib=disabled
#         -Dxlib-xcb=disabled
#         -Dxcb=disabled
#     )
# elif test $(uname) == Linux ; then
#     meson_config_args+=(-Dxlib-xcb=enabled)
# fi

meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --default-library=static \
    --prefix=$PREFIX \
    -Dlibdir=lib \
    --wrap-mode=nofallback \
    --cross-file=$RECIPE_DIR/emscripten.meson.cross
ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}
