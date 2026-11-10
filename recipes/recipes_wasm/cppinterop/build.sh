#!/bin/bash
set -euxo pipefail

emcmake cmake ${CMAKE_ARGS} -S "${SRC_DIR}" -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DLLVM_DIR="${PREFIX}/lib/cmake/llvm" \
  -DClang_DIR="${PREFIX}/lib/cmake/clang" \
  -DLLD_DIR="${PREFIX}/lib/cmake/lld" \
  -DCPPINTEROP_TABLEGEN_EXE="${BUILD_PREFIX}/bin/cppinterop-tblgen" \
  -DCPPINTEROP_CLANG_RESOURCE_DIR="/lib/clang/23" \
  -DCPPINTEROP_ENABLE_TESTING=OFF \
  -DCPPINTEROP_SHARED_LIBRARY_VERSIONING=OFF \
  -DBUILD_SHARED_LIBS=ON

ninja -C build -j "${CPU_COUNT:-2}"
ninja -C build install
