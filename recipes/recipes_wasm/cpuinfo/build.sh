#!/bin/bash
set -e

emcmake cmake . \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCPUINFO_LIBRARY_TYPE=static \
  -DCPUINFO_BUILD_TOOLS=OFF \
  -DCPUINFO_BUILD_UNIT_TESTS=OFF \
  -DCPUINFO_BUILD_MOCK_TESTS=OFF \
  -DCPUINFO_BUILD_BENCHMARKS=OFF \
  -DCPUINFO_BUILD_PKG_CONFIG=OFF \
  -Bcmake-out-wasm

cd cmake-out-wasm

emmake cmake --build . --target install
