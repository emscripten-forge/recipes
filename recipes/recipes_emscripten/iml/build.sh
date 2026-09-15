#!/usr/bin/env bash
set -euxo pipefail

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --with-gmp-include="${PREFIX}/include" \
    --with-gmp-lib="${PREFIX}/lib" \
    --with-cblas="-L${PREFIX}/lib -lopenblas" \
    --disable-shared \
    --prefix="${PREFIX}" \
    CPPFLAGS="-I${PREFIX}/include" \
    CFLAGS="${CFLAGS:-}" \
    LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"

emmake make -j8
emmake make install