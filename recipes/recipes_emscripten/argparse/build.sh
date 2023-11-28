#!/bin/sh

mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DARGPARSE_BUILD_TESTS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      $SRC_DIR

make VERBOSE=1 -j${CPU_COUNT}
make install