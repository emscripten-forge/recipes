#!/bin/bash

mkdir -p build

cd build



# to build without curl we need to disable projsync too
emcmake cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_APPS=OFF \
      -DBUILD_TESTING=OFF \
      -DENABLE_CURL=OFF \
      -DBUILD_PROJSYNC=OFF \
      -DSQLite3_INCLUDE_DIR=$PREFIX/include \
      -DSQLite3_LIBRARY=$PREFIX/lib/libsqlite3.a \
      -DTIFF_INCLUDE_DIR=$PREFIX/include \
      -DTIFF_LIBRARY=$PREFIX/lib/libtiff.a \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON

emmake make -j${CPU_COUNT} #${VERBOSE_CM}

emmake make install -j${CPU_COUNT}

