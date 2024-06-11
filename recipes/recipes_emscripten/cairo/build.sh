#!/bin/bash

set -ex

meson_config_args=(
    -Dfontconfig=enabled
    -Dfreetype=disabled
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



# bash autogen.sh
# chmod +x ./configure

# export ax_cv_c_float_words_bigendian=no

# emconfigure ./configure \
#     --prefix="${PREFIX}" \
#     --enable-ft \
#     --enable-ps \
#     --enable-pdf \
#     --enable-svg \
#     --disable-gtk-doc \
#     --enable-xcb-shm

# emmake make -j${CPU_COUNT}
# # FAIL: check-link on OS X
# # Hangs for > 10 minutes on Linux
# #make check -j${CPU_COUNT}
# emmake make install -j${CPU_COUNT}

# # Remove any new Libtool files we may have installed. It is intended that
# # conda-build will eventually do this automatically.
# find $PREFIX -name '*.la' -delete