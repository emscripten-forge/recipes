#!/bin/bash

if [[ $target_platform == "emscripten-wasm32" ]]; then
    cp ${RECIPE_DIR}/setup.py ${SRC_DIR}/python/
    cp ${RECIPE_DIR}/CMakeLists.txt ${SRC_DIR}/python/
    cp ${RECIPE_DIR}/FindPythonLibsNew.cmake ${SRC_DIR}/cpp/cmake_modules/
    cp ${RECIPE_DIR}/FindPython3Alt.cmake ${SRC_DIR}/cpp/cmake_modules/
    cp ${RECIPE_DIR}/SetupCxxFlags.cmake ${SRC_DIR}/cpp/cmake_modules/
fi



export INCLUDE_NUMPY_FLAGS="-I$BUILD_PREFIX/lib/python3.11/site-packages/numpy/core/include   -I$PREFIX/lib/python3.11/site-packages/numpy/core/include" 

export CFLAGS="$CFLAGS $INCLUDE_NUMPY_FLAGS"
export CXXFLAGS="$CXXFLAGS $INCLUDE_NUMPY_FLAGS"


export CFLAGS="$CFLAGS -sWASM_BIGINT"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT"

cd python
${PYTHON} -m pip install . -vvv 

INIT_PATH=$PREFIX/lib/python3.11/site-packages/pyarrow/__init__.py

sed -i "s/__version__ = None/__version__ = \"$PKG_VERSION\"/g" $INIT_PATH