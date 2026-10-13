#!/bin/bash

mkdir -p build
cd build

emcmake cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DBUILD_SHARED_LIBS=OFF
emmake make -j${CPU_COUNT}
emmake make install