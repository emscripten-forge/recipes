#!/bin/bash

unset CMAKE_CXX_FLAGS
eport CMAKE_CXX_FLAGS=""

export CXXFLAGS="--std=c++17"
export CMAKE_CXX_STANDARD=17

export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -std=c++14  -s LZ4=1 -s SIDE_MODULE=1 -sWASM_BIGINT"
${PYTHON} -m pip install .



if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
    sed -i.bak '1s@.*@#!/usr/bin/env python@' $BUILD_PREFIX/bin/cython
    sed -i.bak '1s@.*@#!/usr/bin/env python@' $PREFIX/bin/cython
    rm $PREFIX/bin/cython.bak
fi


PYTHON_ARGS="-D IGNORE_THIS=1"
for ARG in $CMAKE_ARGS; do
  if [[ "$ARG" == "-DCMAKE_"* ]] && [[ "$ARG" != *";"* ]]; then
    cmake_arg=$(echo $ARG | cut -d= -f1)
    cmake_arg=$(echo $cmake_arg| cut -dD -f2-)
    cmake_val=$(echo $ARG | cut -d= -f2-)
    PYTHON_ARGS="$PYTHON_ARGS;${cmake_arg}=${cmake_val}"
  fi
done

$PYTHON setup.py build_ext --symengine-dir=$PREFIX $PYTHON_ARGS bdist_wheel
$PYTHON -m pip install dist/symengine*.whl
