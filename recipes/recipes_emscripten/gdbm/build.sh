#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

export CPPFLAGS="${CPPFLAGS:-} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"
export CXXFLAGS="${CXXFLAGS:-} -std=c++11"
export CFLAGS="${CFLAGS:-} -Wno-implicit-function-declaration"

emconfigure ./configure \
    ${CONFIGURE_ARGS:-} \
    --prefix="${PREFIX}" \
    --build=$(./build-aux/config.guess) \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --enable-libgdbm-compat \
    --disable-dependency-tracking \
    --disable-nls

emmake make -j${CPU_COUNT:-1}

emmake make install

shopt -s nullglob
for wasm_file in *.wasm src/*.wasm tools/*.wasm; do
    if [ -f "$wasm_file" ]; then
        cp "$wasm_file" "${PREFIX}/bin/"
    fi
done
shopt -u nullglob