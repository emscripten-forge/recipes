#!/usr/bin/env bash
set -euxo pipefail

autoreconf --install

emconfigure ./configure \
    --prefix="${PREFIX}" \
    --disable-shared \
    --enable-static \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib"

emmake make

emmake make install
