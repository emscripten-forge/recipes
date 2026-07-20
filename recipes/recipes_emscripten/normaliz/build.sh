#!/usr/bin/env bash
set -euxo pipefail

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
export CFLAGS="-fPIC"
export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"
export CXXFLAGS="-std=c++17 -fPIC -Wno-invalid-utf8 -Wno-unused-but-set-variable -Wno-deprecated-declarations"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-dependency-tracking \
    --disable-shared \
    --with-gmp="${PREFIX}" \
    --with-flint="${PREFIX}" \
    --with-cocoalib="${PREFIX}" \
    --with-nauty="${PREFIX}" \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install
cp source/normaliz.wasm "${PREFIX}/bin"
