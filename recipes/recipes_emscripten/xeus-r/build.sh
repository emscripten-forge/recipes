#!/bin/bash

set -eux

rm $PREFIX/lib/libz.so* || true

# Install r-hera
$R CMD INSTALL $R_ARGS hera

# Create build directory
mkdir -p build
cd build

# Set up the environment variables for cross-compiling to WASM
export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# Configure step with Emscripten's emcmake
emcmake cmake ${CMAKE_ARGS} -S .. -B .                     \
    -DCMAKE_BUILD_TYPE=Release                             \
    -DCMAKE_PREFIX_PATH=$PREFIX                            \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                         \
    -DXEUS_R_EMSCRIPTEN_WASM_BUILD=ON                      \
    -DCMAKE_VERBOSE_MAKEFILE=ON

# Build step with emmake
emmake make -j1

# Install step
emmake make install

cat $PREFIX/share/jupyter/kernels/xr/kernel.json
