#!/bin/bash

export CONDA_BUILD_CROSS_COMPILATION="1"

declare -a CMAKE_PLATFORM_FLAGS
if [[ ${target_platform} == osx-64 ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
fi

mkdir build && cd build
cmake ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    "${CMAKE_PLATFORM_FLAGS[@]}" \
    $SRC_DIR

make install -j ${CPU_COUNT}

cd ..
cd htmlreport

$PYTHON setup.py install --single-version-externally-managed --record=record.txt
