#!/bin/bash

mkdir -p build
cd build

emcmake cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${PREFIX}
emmake make -j${CPU_COUNT}
emmake make install