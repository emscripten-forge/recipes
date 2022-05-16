#!/bin/bash
mkdir -p build
cd build

emcmake cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DENABLE_CONDA=ON \
      -DMULTI_SEMANTICS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DDISABLE_SHARED=ON\
      -DENABLE_STATIC=ON \
      -DZLIB_USE_STATIC_LIBS=ON \
      -DZLIB_LIBRARY=$PREFIX/lib/libz_static.a \
      -DZLIB_INCLUDE_DIR=$PREFIX/include \
      ${CMAKE_ARGS} \
      ..

emmake make VERBOSE=1 -j${CPU_COUNT} install