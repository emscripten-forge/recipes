#!/bin/bash
set -ex

# The 6x toolchain builds without pthread support: disable configure's
# AX_PTHREAD detection (the option is --without-threads, despite the help
# text) and lcms2's pthread-based default mutex plugin.
export CFLAGS="$CFLAGS -DCMS_NO_PTHREADS=1"

emconfigure ./configure \
    --prefix=$PREFIX \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --without-threads \
    --with-tiff=$PREFIX \
    --with-jpeg=$PREFIX

emmake make -j${CPU_COUNT}
emmake make install
