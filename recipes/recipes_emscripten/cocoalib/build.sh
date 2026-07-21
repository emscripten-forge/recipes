#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
emconfigure ./configure \
    --with-libgmp="${PREFIX}/lib/libgmp.a" \
    --only-cocoalib \
    --prefix="${PREFIX}"

emmake make library -j8
emmake make install