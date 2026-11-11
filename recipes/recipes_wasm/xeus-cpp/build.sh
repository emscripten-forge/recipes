#!/bin/bash
set -euxo pipefail

sysroot_path="${EMSCRIPTEN_FORGE_EMSDK_DIR}/upstream/emscripten/cache/sysroot"

emcmake cmake ${CMAKE_ARGS} -S "${SRC_DIR}" -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DXEUS_CPP_KERNELSPEC_PATH="/bin/" \
  -DXEUS_CPP_BUILD_TESTS=OFF \
  -DSYSROOT_PATH="${sysroot_path}"

ninja -C build -j "${CPU_COUNT:-2}"
ninja -C build install
