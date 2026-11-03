#!/usr/bin/env bash
set -euxo pipefail

emcmake cmake ${CMAKE_ARGS} -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DBUILD_TESTS=OFF

emmake make -C build -j${CPU_COUNT}
emmake make -C build install

# cmake only installs primesieve.js
cp build/primesieve.wasm "${PREFIX}/bin/"
