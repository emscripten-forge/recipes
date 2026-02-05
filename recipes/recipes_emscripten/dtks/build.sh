#!/bin/bash
set -e

# add nanobind dir to cmake args
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"


export PYTHON_LIBRARIES=$PREFIX/lib/libpython${PY_VER}.a
export PYTHON_INCLUDE_DIRS=$PREFIX/include/python${PY_VER}
export PYTHON_SITE_PACKAGES=$PREFIX/lib/python${PY_VER}/site-packages
export PYTHON_PREFIX=$PREFIX
export PYTHON_MODULE_EXTENSION=".so"
export PYTHON_MODULE_PREFIX=""
export PYTHON_IS_DEBUG=0

CMAKE_ARGS="${CMAKE_ARGS} \
    -DPython_INCLUDE_DIR=$PREFIX/include/python${PY_VER} \
    -DPYTHONLIBS_FOUND=TRUE \
    -DPYTHON_LIBRARIES=$PREFIX/lib/libpython${PY_VER}.a \
    -DPYTHON_INCLUDE_DIRS=$PREFIX/include/python${PY_VER} \
    -DPYTHON_SITE_PACKAGES=$PREFIX/lib/python${PY_VER}/site-packages \
    -DPYTHON_PREFIX=$PREFIX \
    -DPYTHON_MODULE_EXTENSION=.so \
    -DPYTHON_MODULE_PREFIX= \
    -DPYTHON_IS_DEBUG=0 \
    -DPYTHON_VERSION=${PY_VER}"


export CMAKE_ARGS



mkdir build
cd build
cmake .. \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
    -DXPYT_EMSCRIPTEN_WASM_BUILD=ON \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    ${CMAKE_ARGS}

make -j8 install