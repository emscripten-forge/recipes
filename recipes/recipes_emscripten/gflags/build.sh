#!/bin/bash
set -euo pipefail

if [ -n "${BUILD_PREFIX:-}" ] && [ -f "${BUILD_PREFIX}/bin/activate_emscripten.sh" ]; then
  # pixi's rattler-build path can skip the normal toolchain activation.
  # Source it here so emcmake/emmake resolve with the build Python and SDK vars.
  source "${BUILD_PREFIX}/bin/activate_emscripten.sh"
  export PATH="${BUILD_PREFIX}/bin:${PATH}"
  export PYTHON="${BUILD_PREFIX}/bin/python3"
  export EMSDK_PYTHON="${BUILD_PREFIX}/bin/python3"
fi

emcmake_cmd="${BUILD_PREFIX:-}/bin/emcmake"
emmake_cmd="${BUILD_PREFIX:-}/bin/emmake"

if [ ! -x "${emcmake_cmd}" ]; then
  emcmake_cmd="$(command -v emcmake)"
fi

if [ ! -x "${emmake_cmd}" ]; then
  emmake_cmd="$(command -v emmake)"
fi

"${emcmake_cmd}" cmake -S . -B build \
  -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DGFLAGS_LIBRARY_INSTALL_DIR=lib \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_STATIC_LIBS=ON \
  -DBUILD_TESTING=OFF \
  -DBUILD_gflags_LIB=ON \
  -DBUILD_gflags_nothreads_LIB=ON \
  -DINSTALL_HEADERS=ON \
  -DINSTALL_SHARED_LIBS=OFF \
  -DINSTALL_STATIC_LIBS=ON \
  -DREGISTER_BUILD_DIR=OFF \
  -DREGISTER_INSTALL_PREFIX=OFF

"${emmake_cmd}" ninja -C build -j"${CPU_COUNT}"
"${emmake_cmd}" ninja -C build install