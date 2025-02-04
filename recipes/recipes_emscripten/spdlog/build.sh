#!/bin/bash

mkdir build
cd build

echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)"> $SRC_DIR/shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s SIDE_MODULE=1\")">> $SRC_DIR/shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s SIDE_MODULE=1\")">> $SRC_DIR/shared_lib_patch.cmake
echo "set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules">> $SRC_DIR/shared_lib_patch.cmake

cmake ${CMAKE_ARGS} \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_INSTALL_PREFIX=$PREFIX \
  -D SPDLOG_BUILD_TESTS=OFF \
  -D CMAKE_INSTALL_LIBDIR=lib \
  -D CMAKE_PROJECT_INCLUDE=$SRC_DIR/shared_lib_patch.cmake \
  -D SPDLOG_BUILD_SHARED=ON \
  -D SPDLOG_BUILD_EXAMPLE=OFF \
  -D SPDLOG_FMT_EXTERNAL=ON ..

make -j${CPU_COUNT}
make install
