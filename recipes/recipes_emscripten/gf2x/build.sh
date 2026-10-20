#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

export CFLAGS_FOR_BUILD="-O2"
export CXXFLAGS_FOR_BUILD="-O2"
export CPPFLAGS_FOR_BUILD=""
export LDFLAGS_FOR_BUILD=""

export HOST_CFLAGS="-O2"
export HOST_CXXFLAGS="-O2"
export HOST_LDFLAGS=""

BUILD_ARCH=$("${CC_FOR_BUILD:-cc}" -dumpmachine || echo "x86_64-pc-linux-gnu")

emconfigure ./configure \
    --build="${BUILD_ARCH}" \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --prefix="${PREFIX}" \
    CC_FOR_BUILD="${CC_FOR_BUILD:-cc}" \
    CPP_FOR_BUILD="${CC_FOR_BUILD:-cc} -E" \
    HOST_CC="${CC_FOR_BUILD:-cc}" \
    ABI=32

emmake make -j${CPU_COUNT:-4} 
emmake make install