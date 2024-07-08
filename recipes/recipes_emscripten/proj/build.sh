#!/bin/bash

mkdir -p build

cd build

export LIBS=${BUILD_PREFIX}/include

# to build without curl we need to disable projsync too
emcmake cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_APPS=OFF \
      -DBUILD_TESTING=OFF \
      -DENABLE_CURL=OFF \
      -DBUILD_PROJSYNC=OFF \
      -DSQLite3_INCLUDE_DIR=${LIBS} \
      -DSQLite3_LIBRARY=${LIBS} \
      -DTIFF_INCLUDE_DIR=${LIBS} \
      -DTIFF_LIBRARY=${LIBS} \
      #-DCMAKE_PROJECT_INCLUDE=overwriteProp.cmake \ 

emmake make -j${CPU_COUNT} #${VERBOSE_CM}

emmake make install -j${CPU_COUNT}

