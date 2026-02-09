#!/bin/bash

cp $RECIPE_DIR/CMakeLists.txt $SRC_DIR


# unset CMAKE_CXX_FLAGS
# export CMAKE_CXX_FLAGS=""

# export CXXFLAGS="--std=c++17"
# export CMAKE_CXX_STANDARD=17

# export LDFLAGS="-sMODULARIZE=1 -sLINKABLE=1 -sEXPORT_ALL=1 -sLZ4=1 -sSIDE_MODULE=1 -sWASM_BIGINT"
${PYTHON} -m pip install .
