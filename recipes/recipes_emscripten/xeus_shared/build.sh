#!/bin/bash
set -ex

mkdir build
cd build

# Configure step
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBUILD_SHARED_LIBS=ON         \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX

# Build & Install step
emmake make -j8 install
