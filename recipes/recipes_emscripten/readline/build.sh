#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c89" \

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --with-curses \
    CFLAGS="${CFLAGS:-} -DHAVE_POSIX_SIGNALS" \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install