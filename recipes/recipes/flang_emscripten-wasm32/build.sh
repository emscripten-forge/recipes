#!/bin/bash

set -ex

cmake -S llvm -B _fbuild -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-unknown-emscripten \
        -DLLVM_TARGETS_TO_BUILD=WebAssembly \
        -DLLVM_ENABLE_PROJECTS="clang;flang;mlir"
cmake --build _fbuild
cmake --build _fbuild --target install