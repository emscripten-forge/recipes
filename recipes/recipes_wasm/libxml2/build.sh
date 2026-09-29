#!/bin/bash

export CFLAGS="${CFLAGS} -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -fwasm-exceptions"

mkdir build
cd build

cmake ${CMAKE_ARGS} ..             \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DLIBXML2_WITH_PYTHON=OFF      \
    -DLIBXML2_WITH_THREADS=OFF     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \

emmake make -j${CPU_COUNT:-3}
emmake make install