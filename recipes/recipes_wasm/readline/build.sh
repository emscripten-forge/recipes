#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c89" \

if [[ "${target_platform}" == "emscripten-wasm64" ]]; then
  host="wasm64-unknown-emscripten"
elif [[ "${target_platform}" == "emscripten-wasm32" ]]; then
  host="wasm32-unknown-emscripten"
else
  echo "Unsupported target_platform: $target_platform"
  exit 1
fi

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=$host \
    --disable-shared \
    --enable-static \
    --with-curses \
    CFLAGS="${CFLAGS:-} -DHAVE_POSIX_SIGNALS" \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install