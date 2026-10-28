#!/bin/bash
set -euo pipefail

emcmake cmake -S . -B build -GNinja \
    ${CMAKE_ARGS:-} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON \
    -DSDL_STATIC=ON \
    -DSDL_SHARED=OFF \
    -DSDL_PTHREADS=OFF \
    -DSDL_TESTS=OFF \
    -DSDL_EXAMPLES=OFF \
    -DSDL_TEST_LIBRARY=OFF \
    -DSDL_INSTALL_TESTS=OFF \
    -DSDL_INSTALL_DOCS=OFF \
    -DSDL_CCACHE=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON

emmake ninja -C build -j"${CPU_COUNT:-1}"
emmake ninja -C build install

# Build the browser demo against the just-installed SDL3 package.
bash "$RECIPE_DIR/build_demo.sh"
