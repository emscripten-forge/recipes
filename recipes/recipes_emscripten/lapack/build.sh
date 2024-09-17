#!/bin/bash

set -ex

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
micromamba install -p $BUILD_PREFIX \
    conda-forge/label/llvm_rc::libllvm19=19.1.0.rc2 \
    conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
    -y --no-channel-priority
rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-18 $BUILD_PREFIX/bin/clang # links to emsdk clang

export FC=flang-new
export FFLAGS="--target=wasm32-unknown-emscripten -fPIC"

emcmake cmake -S . -B _build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCBLAS=ON \
    -DLAPACKE=OFF \
    -DBUILD_TESTING=OFF \
    -DCMAKE_Fortran_PREPROCESS=yes \
    -DCMAKE_Fortran_COMPILER=$FC \
    -DCMAKE_Fortran_FLAGS="$FFLAGS" \
    -DCMAKE_INSTALL_LIBDIR="lib" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX

$(which cmake) --build _build
$(which cmake) --install _build
