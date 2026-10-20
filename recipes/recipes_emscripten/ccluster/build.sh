#!/usr/bin/env bash
set -euxo pipefail


CFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CC="emcc" \
emconfigure ./configure \
    --prefix="${PREFIX}" \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --with-flint="${PREFIX}"

emmake make static -j8
emmake make install CCLUSTER_SHARED=0 CCLUSTER_STATIC=1