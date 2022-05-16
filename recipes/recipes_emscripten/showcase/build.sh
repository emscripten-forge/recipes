#!/bin/bash

mkdir build
cd build


mkdir -p usr/local/lib/python3.11

cp -r ${PREFIX}/lib/python3.11 usr/local/lib/


# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \

# Build step
ninja install
