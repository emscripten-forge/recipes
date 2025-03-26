#!/bin/bash
set -x
mkdir build
cd build

cmake ${CMAKE_ARGS} \
  -DLIBDEFLATE_BUILD_STATIC_LIB=ON \
  -DLIBDEFLATE_BUILD_SHARED_LIB=OFF \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  ..

make -j ${CPU_COUNT}

make install