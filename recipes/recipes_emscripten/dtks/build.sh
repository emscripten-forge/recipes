#!/bin/bash
set -e

# add nanobind dir to cmake args
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"


export PYTHON_LIBRARIES=$PREFIX/lib/libpython3.13.a
export PYTHON_INCLUDE_DIRS=$PREFIX/include/python3.13
export PYTHON_SITE_PACKAGES=$PREFIX/lib/python3.13/site-packages
export PYTHON_PREFIX=$PREFIX
export PYTHON_MODULE_EXTENSION=".so"
export PYTHON_MODULE_PREFIX=""
export PYTHON_IS_DEBUG=0

CMAKE_ARGS="${CMAKE_ARGS} \
    -DPython_INCLUDE_DIR=$PREFIX/include/python3.13 \
    -DPYTHONLIBS_FOUND=TRUE \
    -DPYTHON_LIBRARIES=$PREFIX/lib/libpython3.13.a \
    -DPYTHON_INCLUDE_DIRS=$PREFIX/include/python3.13 \
    -DPYTHON_SITE_PACKAGES=$PREFIX/lib/python3.13/site-packages \
    -DPYTHON_PREFIX=$PREFIX \
    -DPYTHON_MODULE_EXTENSION=.so \
    -DPYTHON_MODULE_PREFIX= \
    -DPYTHON_IS_DEBUG=0"


export CMAKE_ARGS

#!/bin/bash
${PYTHON} -m pip  install . --prefix="$PREFIX"
