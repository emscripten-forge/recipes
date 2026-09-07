#!/bin/bash

set -euxo pipefail

cmake -S "${SRC_DIR}/llvm" -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="clang;mlir" \
  -DLLVM_TARGETS_TO_BUILD="" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DMLIR_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DLLVM_BUILD_TOOLS=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_ZLIB=OFF

cmake --build build \
  --target llvm-tblgen llvm-min-tblgen clang-tblgen mlir-tblgen mlir-linalg-ods-yaml-gen \
  --parallel "${CPU_COUNT:-2}"

mkdir -p "${PREFIX}/bin"
cp build/bin/llvm-tblgen "${PREFIX}/bin/"
cp build/bin/llvm-min-tblgen "${PREFIX}/bin/"
cp build/bin/clang-tblgen "${PREFIX}/bin/"
cp build/bin/mlir-tblgen "${PREFIX}/bin/"
cp build/bin/mlir-linalg-ods-yaml-gen "${PREFIX}/bin/"
cp build/bin/llvm-lit "${PREFIX}/bin/"
