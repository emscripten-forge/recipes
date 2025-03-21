#!/bin/bash

set -ex

export CFLAGS="-fPIC $EM_FORGE_SIDE_MODULE_LDFLAGS"
export CXXFLAGS="-fPIC $EM_FORGE_SIDE_MODULE_LDFLAGS"
export LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"

export AR="emar"
export ARFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"
export ARCH="emar"

# See https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
emcmake cmake -S flang/runtime -B _fbuild_runtime -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX \
                -DCMAKE_C_FLAGS="$CFLAGS" \
                -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
                -DCMAKE_ARFLAGS="$ARFLAGS" \
                -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
                -DBUILD_SHARED_LIBS=ON

cd _fbuild_runtime
ninja -v
ninja install

emcc $PREFIX/lib/libFortranRuntime.a -o tst.so -sSIDE_MODULE=1
