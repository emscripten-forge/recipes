#!/bin/bash

cmake ./compile ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib \
    -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=ON \
    -DUSE_OPENMP=OFF

make -j${CPU_COUNT}

${PYTHON} -m pip  install . -vv --install-option=--nomp
