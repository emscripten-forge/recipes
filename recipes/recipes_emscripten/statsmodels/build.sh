#!/bin/bash

export CFLAGS="$CFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions" 
export LDFLAGS="$LDFLAGS  -L $BUILD_PREFIX/lib/python3.13/site-packages/numpy/_core/lib" 
export LDFLAGS="$LDFLAGS  -L $BUILD_PREFIX/lib/python3.13/site-packages/numpy/random/lib" 



${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation 
