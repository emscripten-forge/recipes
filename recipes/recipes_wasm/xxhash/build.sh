#!/bin/bash

set -euxo pipefail

# Use the CMake build to get a static library only (the Makefile also
# builds a shared library and the xxhsum CLI)
emcmake cmake ${CMAKE_ARGS} -S build/cmake -B _build \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DXXHASH_BUILD_XXHSUM=OFF

ninja -C _build install
