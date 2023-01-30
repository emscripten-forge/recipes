#!/bin/bash

if [[ $target_platform == "emscripten-32" ]]; then
    cp ${RECIPE_DIR}/setup.py ${SRC_DIR}/python/
    cp ${RECIPE_DIR}/CMakeLists.txt ${SRC_DIR}/python/
    cp ${RECIPE_DIR}/FindPythonLibsNew.cmake ${SRC_DIR}/cpp/cmake_modules/
    cp ${RECIPE_DIR}/FindPython3Alt.cmake ${SRC_DIR}/cpp/cmake_modules/
    cp ${RECIPE_DIR}/SetupCxxFlags.cmake ${SRC_DIR}/cpp/cmake_modules/
fi



export INCLUDE_NUMPY_FLAGS="-I$BUILD_PREFIX/lib/python3.10/site-packages/numpy/core/include   -I$PREFIX/lib/python3.10/site-packages/numpy/core/include" 

export CFLAGS="$CFLAGS $INCLUDE_NUMPY_FLAGS"
export CXXFLAGS="$CXXFLAGS $INCLUDE_NUMPY_FLAGS"

cd python
${PYTHON} -m pip install . -vvv