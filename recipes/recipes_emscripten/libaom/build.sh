#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="${CXXFLAGS:-} $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="${LDFLAGS:-} $EM_FORGE_SIDE_MODULE_LDFLAGS"

mkdir -p _build
cd _build

emcmake cmake \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS" \
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS" \
    -DAOM_TARGET_CPU=generic \
    -DCONFIG_RUNTIME_CPU_DETECT=0 \
    -DCONFIG_MULTITHREAD=0 \
    -DCONFIG_PIC=0 \
    -DCONFIG_WEBM_IO=0 \
    -DCONFIG_LIBYUV=0 \
    -DENABLE_EXAMPLES=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_TOOLS=OFF \
    -DENABLE_DOCS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    ..

ninja install

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
