#!/bin/bash
set -e

NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
# extension suffix of the (cross) target python, not of the build python
TARGET_EXT_SUFFIX=$("${PYTHON}" -c 'import sysconfig; print(sysconfig.get_config_var("EXT_SUFFIX"))')

mkdir build
cd build
emcmake cmake .. ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
    -Dnanobind_DIR=${NANOBIND_CMAKE_DIR} \
    -DNB_SUFFIX=${TARGET_EXT_SUFFIX} \
    -DPython_EXECUTABLE=${PYTHON} \
    -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER} \
    -DPYTHON_SITE_PACKAGES=${PREFIX}/lib/python${PY_VER}/site-packages

emmake make -j${CPU_COUNT} install
