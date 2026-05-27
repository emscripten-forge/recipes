#!/bin/bash
set -exuo pipefail

# Set default values for potentially unset variables
EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
EM_FORGE_SIDE_MODULE_LDFLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"
CFLAGS="${CFLAGS:-}"
CXXFLAGS="${CXXFLAGS:-}"
LDFLAGS="${LDFLAGS:-}"

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

mkdir -p build
cd build

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DBUILD_SHARED_LIBS=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=OFF \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_EXAMPLES=OFF \
    -Dprotobuf_BUILD_CONFORMANCE=OFF \
    -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
    -Dprotobuf_BUILD_LIBPROTOC=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_PROTOBUF_BINARIES=ON \
    -Dprotobuf_INSTALL=ON \
    -Dprotobuf_LOCAL_DEPENDENCIES_ONLY=ON \
    -Dprotobuf_WITH_ZLIB=ON \
    -Dprotobuf_ABSL_PROVIDER=package \
    ..

ninja install

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
