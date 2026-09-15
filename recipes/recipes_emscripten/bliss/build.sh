#!/usr/bin/env bash
set -euxo pipefail

strip_arch() { echo "${1:-}" | sed -E 's/-march=[^ ]+//g; s/-mtune=[^ ]+//g'; }
export CFLAGS="-I$PREFIX/include $(strip_arch "${CFLAGS:-}")"
export CXXFLAGS="-I$PREFIX/include $(strip_arch "${CXXFLAGS:-}")"
export LDFLAGS="-L$PREFIX/lib ${LDFLAGS:-}"

emcmake cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DUSE_GMP=ON \
    -DGMP_INCLUDE_DIR="$PREFIX/include" \
    -DGMP_LIBRARIES="$PREFIX/lib/libgmp.a"

cmake --build build -j"${CPU_COUNT:-1}"
cmake --install build

cp build/bliss.wasm "$PREFIX/bin/"
