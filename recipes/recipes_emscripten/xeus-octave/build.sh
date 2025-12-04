#!/bin/bash

set -eux

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} -S .. -B .                     \
    -DCMAKE_BUILD_TYPE=Release                             \
    -DCMAKE_PREFIX_PATH=$PREFIX                            \
    -DCMAKE_SYSTEM_PREFIX_PATH=$PREFIX                     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                         \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX"                       \
    -DCMAKE_VERBOSE_MAKEFILE=OFF

emmake make install

cat $PREFIX/share/jupyter/kernels/xoctave/kernel.json