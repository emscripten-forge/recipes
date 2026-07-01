#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \

emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --with-libgmp="${PREFIX}" \
    --with-libcddgmp="${PREFIX}" \
    --with-frobby="${PREFIX}" \
    --with-libgfan="${PREFIX}" \
    --with-libgsl="${PREFIX}" \
    --with-libnormaliz="${PREFIX}" \
    --no-readline
    --prefix="${PREFIX}"

emmake make -j8
emmake make install