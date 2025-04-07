#!/bin/bash

mkdir -p build

cd build

emcmake cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DOSQP_ENABLE_INTERRUPT=OFF \
      -DOSQP_CODEGEN=OFF \
      -DOSQP_BUILD_SHARED_LIB=OFF \

emmake make -j${CPU_COUNT}

emmake make install -j${CPU_COUNT}
