#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

export CPPFLAGS="-I${PREFIX}/include"
# THREAD_SAFE_GT=0 keeps schoen_strass.c from using pthread TLS.
# It goes into CFLAGS because configure overwrites CPPFLAGS for --with-gmp.
export CFLAGS="-O2 -DTHREAD_SAFE_GT=0"
export LDFLAGS="-L${PREFIX}/lib"
export CXXFLAGS="-std=c++11"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=${HOST} \
    --with-gmp="${PREFIX}" \
    --disable-shared \
    --prefix="${PREFIX}"

emmake make -j8 
emmake make install

cp ecm.wasm "${PREFIX}/bin"