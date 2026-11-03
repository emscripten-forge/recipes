#!/usr/bin/env bash
set -euxo pipefail

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"
export CXXFLAGS="${CXXFLAGS:-} -std=c++11"
export CFLAGS="${CFLAGS:-} -Wno-implicit-function-declaration"

emconfigure ./configure \
    --host=${HOST} \
    --disable-shared \
    --enable-static \
    --disable-openmp \
    --prefix="${PREFIX}"

emmake make -j${CPU_COUNT:-4}
emmake make install

cp *.wasm "${PREFIX}/bin/"
rm -f "${PREFIX}/bin/a.wasm"
