#!/bin/bash
set -euo pipefail

emcmake cmake -S . -B build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DGGML_WEBGPU=ON \
  -DGGML_OPENMP=OFF \
  -DGGML_CCACHE=OFF \
  -DGGML_BUILD_TESTS=OFF \
  -DGGML_BUILD_EXAMPLES=OFF \
  -DEMSCRIPTEN_SYSTEM_PROCESSOR=wasm

emmake ninja -C build -j"${CPU_COUNT}"

emmake ninja -C build install
