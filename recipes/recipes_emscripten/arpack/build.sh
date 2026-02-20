#!/bin/bash

set -eux

# Install custom LLVM and flang which includes patch for common symbols
LLVM_DIR="$(pwd)/llvm_dir"
LLVM_PKG="llvm_emscripten-wasm32-20.1.7-h2e33cc4_5.tar.bz2"
mkdir -p $LLVM_DIR
wget --quiet https://github.com/IsabelParedes/llvm-project/releases/download/v20.1.7_emscripten-wasm32/$LLVM_PKG
tar -xf $LLVM_PKG --directory $LLVM_DIR

export FC=$LLVM_DIR/bin/flang
export FFLAGS="--target=wasm32-unknown-emscripten"

emcmake cmake -S . -B _build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_Fortran_COMPILER=$FC \
    -DCMAKE_Fortran_FLAGS="$FFLAGS" \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DBUILD_SHARED_LIBS=OFF \
    -DMPI=OFF \
    -DICB=ON \
    -DEIGEN=OFF \
    -DPYTHON3=OFF \
    -DEXAMPLES=OFF \
    -DTESTS=OFF

$(which cmake) --build _build -j${CPU_COUNT:-3}
$(which cmake) --install _build
