#!/bin/bash

set -ex

mkdir -p build
cd build

emcmake cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=${PREFIX} \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=${PREFIX}/lib \
      -DCMAKE_INSTALL_RPATH=${PREFIX}/lib \
      -DENABLE_SHARED=OFF \
      -DENABLE_STATIC=ON \
      ${CMAKE_ARGS} ${SRC_DIR}

make -j${CPU_COUNT} ${VERBOSE_CM}

make -j${CPU_COUNT} install

# Remove examples
rm -r $PREFIX/libexec/lzo
