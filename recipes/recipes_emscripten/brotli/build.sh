#!/bin/bash

set -e

BROTLI_CFLAGS="-O3"

# Build both static and shared libraries
cmake ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib \
      -DCMAKE_C_FLAGS=$BROTLI_CFLAGS \
      -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake \
      -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_STATIC_LIBS=ON \
      -DBUILD_SHARED_LIBS=ON \
      .

ninja install



#!/bin/bash
${PYTHON} -m pip  install .
