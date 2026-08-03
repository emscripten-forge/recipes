#!/bin/bash

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DQDLDL_BUILD_SHARED_LIB=OFF \
      -DQDLDL_BUILD_STATIC_LIB=ON \
      -DQDLDL_BUILD_DEMO_EXE=OFF \
      -DQDLDL_UNITTESTS=OFF

emmake make -j${CPU_COUNT}
emmake make install -j${CPU_COUNT}
