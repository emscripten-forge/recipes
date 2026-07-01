#!/bin/bash
set -e

# Step 1: Build SimpleITK C++ library (without Python wrapping)
# Use CMAKE_ARGS from emscripten environment (set up by emscripten_emscripten-wasm32)
# but strip the Python flags that cross-python adds, as they are not needed here
mkdir -p build_cpp
cd build_cpp



cmake ${CMAKE_ARGS} \
    -GNinja \
    -DITK_DIR="${PREFIX}/lib/cmake/ITK-5.4" \
    -DCMAKE_PROJECT_INCLUDE="${RECIPE_DIR}/overwriteProp.cmake" \
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

emcmake cmake ${CMAKE_ARGS} \
    -G Ninja \
    -D CMAKE_BUILD_TYPE:STRING=Release \
    -D SimpleITK_BUILD_DISTRIBUTE:BOOL=ON \
    -D SimpleITK_BUILD_STRIP:BOOL=ON \
    -D BUILD_SHARED_LIBS:BOOL=OFF \
    -D BUILD_TESTING:BOOL=OFF \
    -D SimpleITK_PYTHON_USE_VIRTUALENV:BOOL=OFF \
    "${SRC_DIR}"/Wrapping/Python

emmake cmake --build . --config Release
"${PYTHON}" -m pip install .