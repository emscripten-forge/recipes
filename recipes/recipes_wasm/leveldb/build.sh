#!/bin/bash
set -e

mkdir build
cd build

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# Configure step
emcmake cmake ${CMAKE_ARGS} ..              \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX}      \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX}   \
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS"       \
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS"   \
    -DCMAKE_MODULE_LINKER_FLAGS_RELEASE="$LDFLAGS" \
    -DCMAKE_INSTALL_LIBDIR=lib              \
    -DCMAKE_BUILD_TYPE=Release              \
    -DBUILD_SHARED_LIBS=OFF                 \
    -DLEVELDB_BUILD_TESTS=OFF               \
    -DLEVELDB_BUILD_BENCHMARKS=OFF          \
    -DLEVELDB_INSTALL=ON

# Build step
emmake make -j${CPU_COUNT} install
