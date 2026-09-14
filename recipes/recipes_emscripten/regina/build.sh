#!/bin/bash
set -euxo pipefail

mkdir -p build-wasm
cd build-wasm

WASM_CXXFLAGS="-O2 -fwasm-exceptions"
WASM_LDFLAGS="-O2 -fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=67108864 -sINITIAL_MEMORY=268435456 -L${PREFIX}/lib -lembind"

cmake ${CMAKE_ARGS} .. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=BOTH \
    -DZLIB_LIBRARY="${PREFIX}/lib/libz.a" \
    -DZLIB_INCLUDE_DIR="${PREFIX}/include" \
    -DQT_HOST_PATH="${BUILD_PREFIX}" \
    -DREGINA_INSTALL_TYPE=XDG \
    -DREGINA_KVSTORE=tkrzw \
    -DDISABLE_PYTHON=ON \
    -DDISABLE_GUI=OFF \
    -DHIGHDIM=OFF \
    -DBUILD_INFO="emscripten-forge WASM build" \
    -DCMAKE_CXX_FLAGS="${WASM_CXXFLAGS}" \
    -DCMAKE_C_FLAGS="${WASM_CXXFLAGS}" \
    -DCMAKE_EXE_LINKER_FLAGS="${WASM_LDFLAGS}"

ninja -j"${CPU_COUNT:-2}"
ninja install

cp qtui/src/regina-gui.js "${PREFIX}/bin/regina-gui.js"
cp qtui/src/regina-gui.wasm "${PREFIX}/bin/regina-gui.wasm"
cp utils/*.wasm "${PREFIX}/bin/"