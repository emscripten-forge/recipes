#!/bin/bash

export CFLAGS="$CFLAGS -fPIC -O3"
export CXXFLAGS="$CXXFLAGS -fPIC -O3"

${PYTHON} -m pip install . -vv
