#!/bin/bash
set -e

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} .. \
    -DBUILD_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX

emmake make install
