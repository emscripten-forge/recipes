#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++17" \
emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"

# gmp and cddlib is compiled without "-pthread" on emscripten-forge, so I had to disable "-pthread" for topcom
find . -name Makefile -exec sed -i 's/-pthread//g' {} +

emmake make -j8
emmake make install

cp src/*.wasm "${PREFIX}/bin/"