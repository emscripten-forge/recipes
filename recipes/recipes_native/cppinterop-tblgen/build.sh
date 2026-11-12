#!/bin/bash
set -euxo pipefail

cmake ${CMAKE_ARGS} -S "${SRC_DIR}" -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_DIR="${PREFIX}/lib/cmake/llvm" \
  -DCPPINTEROP_BUILD_TABLEGEN_ONLY=ON

cmake --build build --target cppinterop-tblgen --parallel "${CPU_COUNT:-2}"

install -Dm755 build/utils/TableGen/cppinterop-tblgen "${PREFIX}/bin/cppinterop-tblgen"
