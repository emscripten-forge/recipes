#!/bin/bash

export CFLAGS="$CFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions -fPIC"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions -fPIC"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions -fPIC"



${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation 
