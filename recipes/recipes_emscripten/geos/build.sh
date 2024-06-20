#!/bin/bash

mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=OFF \
      ..

emmake make -j${CPU_COUNT} #${VERBOSE_CM}

emmake make install -j${CPU_COUNT}
#ctest
