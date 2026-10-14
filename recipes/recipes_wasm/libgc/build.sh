#!/usr/bin/env bash
set -euxo pipefail

mkdir -p build
cd build

emcmake cmake .. \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
    -D BUILD_SHARED_LIBS=OFF \
    -D GC_BUILD_SHARED_LIBS=OFF \
    -D enable_threads=OFF \
    -D enable_emscripten_asyncify=OFF \
    -D enable_cplusplus=ON \
    -D BUILD_TESTING=ON \
    -D build_tests=ON





emmake make -j8

# show all built files
ls

# run all test executables with node
find . -name "*.js" -exec node {} \;

# note from DerThorsten
# tests seem to fail...


emmake make install