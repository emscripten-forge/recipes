#!/usr/bin/env bash
set -euxo pipefail

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"
export CXXFLAGS="-std=c++11"
export CFLAGS="-Wno-implicit-function-declaration"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install

cp *.wasm "${PREFIX}/bin/"