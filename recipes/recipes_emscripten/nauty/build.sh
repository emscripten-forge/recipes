#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
emconfigure ./configure \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install