#!/bin/bash
printenv
exit
mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_PROJECT_INCLUDE=../overwriteProp.cmake
      ..

emmake make -j${CPU_COUNT} #${VERBOSE_CM}

emmake make install -j${CPU_COUNT}
