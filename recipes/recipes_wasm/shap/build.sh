#!/bin/bash
set -e

NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"
# build the extensions as emscripten side modules
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"
# point FindPython at the (cross) target python
CMAKE_ARGS="${CMAKE_ARGS} -DPython_EXECUTABLE=${PYTHON}"
CMAKE_ARGS="${CMAKE_ARGS} -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER}"
CMAKE_ARGS="${CMAKE_ARGS} -DPython_LIBRARY=${PREFIX}/lib/libpython${PY_VER}.a"
export CMAKE_ARGS

${PYTHON} -m pip install . --prefix="$PREFIX" --no-deps --no-build-isolation -vv
