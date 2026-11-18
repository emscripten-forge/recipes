#!/bin/bash
set -e

# The Emscripten CMake toolchain derives CMAKE_SIZEOF_VOID_P from
# CMAKE_C_FLAGS, which stays empty for this CXX-only test project. On
# emscripten-wasm64 that makes abslConfigVersion.cmake (loaded through
# sentencepieceConfig.cmake) report the installed abseil package as 32-bit
# (unsuitable) and find_package() fails, so pass the activated flags
# explicitly.
export CFLAGS="${CFLAGS:-}"
export CXXFLAGS="${CXXFLAGS:-}"

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -DCMAKE_CXX_STANDARD=20

emmake make -C build_tests -j"${CPU_COUNT}"

echo "Running test..."
node build_tests/test_sentencepiece_cpp.js
