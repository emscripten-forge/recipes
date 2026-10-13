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


# Specific variables for cross-compilation
if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    export CHOST="wasm32-unknown-linux" # wasm32-unknown-emscripten
    export ABI=32
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    export CHOST="wasm64-unknown-linux" # wasm64-unknown-emscripten
    export ABI=64
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi

BUILD_ARCH=$("${CC_FOR_BUILD:-cc}" -dumpmachine || echo "x86_64-pc-linux-gnu")

emconfigure ./configure \
    --build="${BUILD_ARCH}" \
    --host="${CHOST}" \
    --disable-shared \
    --prefix="${PREFIX}" \
    CC_FOR_BUILD="${CC_FOR_BUILD:-cc}" \
    CPP_FOR_BUILD="${CC_FOR_BUILD:-cc} -E" \
    HOST_CC="${CC_FOR_BUILD:-cc}" \
    ABI="${ABI}"

emmake make -j${CPU_COUNT:-4} 
emmake make install