#!/bin/bash

mkdir build
cd build
cmake -DLLVM_ENABLE_PROJECTS="clang;lldb" \
      -DLLVM_TARGETS_TO_BUILD=host \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ \
      ../llvm/
make llvm-tblgen clang-tblgen lldb-tblgen -j$(nproc --all)

mkdir -p $PREFIX/bin
cp bin/llvm-tblgen $PREFIX/bin/
cp bin/clang-tblgen $PREFIX/bin/
cp bin/lldb-tblgen $PREFIX/bin/
cp bin/llvm-lit $PREFIX/bin/
cp bin/llvm-min-tblgen $PREFIX/bin/