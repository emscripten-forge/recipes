#!/usr/bin/env bash
set -euxo pipefail

echo "int getdtablesize(void) { return 1024; }" >> sources/tools.c

autoreconf -i

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \
emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static-link \
    --disable-threaded \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --with-zlib="${PREFIX}" \
    --with-zstd="${PREFIX}" \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install

cp sources/form.wasm "${PREFIX}/bin/"