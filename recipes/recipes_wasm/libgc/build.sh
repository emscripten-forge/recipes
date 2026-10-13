#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \



if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    export CHOST="wasm32-unknown-linux" # wasm32-unknown-emscripten
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    export CHOST="wasm64-unknown-linux" # wasm64-unknown-emscripten
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host="$CHOST" \
    --disable-shared \
    --enable-static \
    --disable-threads \
    --disable-emscripten-asyncify \
    --enable-cplusplus \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install
