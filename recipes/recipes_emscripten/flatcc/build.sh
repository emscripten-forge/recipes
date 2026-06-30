#!/bin/bash
set -euo pipefail

emcmake cmake -S . -B build \
  -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DFLATCC_TEST=OFF \
  -DFLATCC_CXX_TEST=OFF \
  -DFLATCC_DEBUG_CLANG_SANITIZE=OFF \
  -DFLATCC_INSTALL=ON \
  -DFLATCC_ALLOW_WERROR=OFF

emmake ninja -C build -j"${CPU_COUNT}"
emmake ninja -C build install

flatcc_wasm="$(find . -path "${PREFIX}" -prune -o -name flatcc.wasm -type f -print | head -n 1 || true)"
if [ -n "${flatcc_wasm}" ]; then
  install -Dm644 "${flatcc_wasm}" "${PREFIX}/bin/flatcc.wasm"
fi