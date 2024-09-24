#!/bin/bash
set -ex

emconfigure ./configure \
    --prefix=${PREFIX} \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --disable-shared \
    --enable-static \
    --disable-symbol-hiding \
    --disable-ldap \
    --disable-threaded-resolver \
    --disable-ipv6 \
    --disable-tftp \
    --with-openssl=${PREFIX} \
    --with-zlib=${PREFIX} \
    --with-zstd=${PREFIX} \
    --without-libpsl \

emmake make -j${CPU_COUNT} ${VERBOSE_AT}

emmake make install
