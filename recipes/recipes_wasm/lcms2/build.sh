#!/bin/bash
set -ex

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
