#!/bin/bash

mkdir build
cd build

export BUILD_TYPE="Release"

cmake ${CMAKE_ARGS} .. -GNinja \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_STATIC_LIBS=ON \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}"

ninja install
