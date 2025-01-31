#!/bin/bash


export CXXFLAGS="--std=c++17"
export CMAKE_CXX_STANDARD=17

export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -std=c++14  -s LZ4=1 -s SIDE_MODULE=1 -sWASM_BIGINT"
${PYTHON} -m pip install .
