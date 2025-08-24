#!/bin/bash
set -e

mkdir -p build
cd build
emcmake cmake .. \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON          \
    -DCMAKE_BUILD_TYPE=Release                      \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                  \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX                  \
    -DBUILD_EXTENSION=OFF                           \
    -DBUILD_WASM_HOST=ON                            \
    -Dpybind11_DIR=$PREFIX/share/cmake/pybind11/    \
    -DBUILD_WASM_HOST=ON

# install
emmake make install