#!/bin/bash
set -e

cmake . \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DFXDIV_BUILD_TESTS=OFF \
  -DFXDIV_BUILD_BENCHMARKS=OFF \
  -Bcmake-out-wasm

cmake --build cmake-out-wasm --target install
