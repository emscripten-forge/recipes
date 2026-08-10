#!/bin/bash

mkdir build
cd build
cmake \
  -DLLVM_ENABLE_PROJECTS="clang;mlir" \
  -DLLVM_TARGETS_TO_BUILD=host \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="clang" \
  -DCMAKE_CXX_COMPILER="clang++" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DMLIR_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_BUILD_TOOLS=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  ../llvm/
make llvm-tblgen clang-tblgen mlir-tblgen mlir-linalg-ods-yaml-gen -j$(nproc --all)

mkdir -p $PREFIX/bin
cp bin/llvm-tblgen $PREFIX/bin/
cp bin/clang-tblgen $PREFIX/bin/
cp bin/mlir-tblgen $PREFIX/bin/
cp bin/mlir-linalg-ods-yaml-gen $PREFIX/bin/
cp bin/llvm-lit $PREFIX/bin/
cp bin/llvm-min-tblgen $PREFIX/bin/
