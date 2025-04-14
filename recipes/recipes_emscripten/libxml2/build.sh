#!/bin/bash

mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DLIBXML2_WITH_PYTHON=OFF      \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \


emmake make -j${CPU_COUNT:-3}
emmake make install