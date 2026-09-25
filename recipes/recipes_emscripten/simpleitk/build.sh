#!/bin/bash
set -e

# Step 1: Build SimpleITK C++ library (without Python wrapping)
# Use CMAKE_ARGS from emscripten environment (set up by emscripten_emscripten-wasm32)
# but strip the Python flags that cross-python adds, as they are not needed here
mkdir -p build_cpp
cd build_cpp

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DSimpleITK_BUILD_DISTRIBUTE=ON \
    -DWRAP_DEFAULT=OFF \
    "${SRC_DIR}"

ninja -j${CPU_COUNT}
ninja install

cd ..

# Step 2: Build the Python wrapper
# CMAKE_ARGS now also contains Python-related flags added by cross-python
mkdir -p build_python
cd build_python

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_PROJECT_INCLUDE="${RECIPE_DIR}/overwriteProp.cmake" \
    -DSimpleITK_BUILD_DISTRIBUTE=ON \
    -DSimpleITK_PYTHON_THREADS=OFF \
    -DSimpleITK_PYTHON_USE_VIRTUALENV=OFF \
    -DSimpleITK_PYTHON_USE_LIMITED_API=OFF \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DSWIG_EXECUTABLE="$(which swig)" \
    "${SRC_DIR}/Wrapping/Python"

ninja -j${CPU_COUNT}

# Install the Python package
"${PYTHON}" -m pip install . ${PIP_ARGS}
