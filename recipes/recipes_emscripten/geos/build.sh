#!/bin/bash

mkdir -p build && cd build

# Force support for shared libraries
echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)" > SupportSharedLib.cmake

emcmake cmake ${CMAKE_ARGS} -GNinja \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=${PREFIX} \
      -D CMAKE_INSTALL_LIBDIR=lib \
      -D BUILD_SHARED_LIBS=ON \
      -D BUILD_TESTING=OFF \
      -D BUILD_BENCHMARKS=OFF \
      -D BUILD_DOCUMENTATION=OFF \
      -D CMAKE_PROJECT_INCLUDE=SupportSharedLib.cmake \
      ${SRC_DIR}

ninja

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    ctest --output-on-failure
fi

ninja install -j${CPU_COUNT}
