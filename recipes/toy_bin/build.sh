#!/bin/bash

mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -Dtoy_lib_DIR=$PREFIX/lib/cmake/toy_lib/ \

# Build step
ninja install
