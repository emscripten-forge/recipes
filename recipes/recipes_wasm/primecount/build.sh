#!/usr/bin/env bash
set -euxo pipefail

# link against primesieve-static instead of the bundled copy
emcmake cmake ${CMAKE_ARGS} -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_LIBPRIMESIEVE=OFF \
    -DWITH_OPENMP=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DBUILD_TESTS=OFF

emmake make -C build -j${CPU_COUNT}
emmake make -C build install

# cmake only installs primecount.js
cp build/primecount.wasm "${PREFIX}/bin/"
