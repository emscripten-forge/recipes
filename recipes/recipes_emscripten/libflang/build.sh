#!/bin/bash

set -ex

export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC"

# See https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
emcmake cmake -S flang/runtime -B _fbuild_runtime -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX

cd _fbuild_runtime
ninja -v
ninja install

emcc $PREFIX/lib/libFortranRuntime.a -o tst.so -sSIDE_MODULE=1 
