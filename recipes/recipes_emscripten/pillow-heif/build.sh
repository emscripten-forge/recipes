#!/bin/bash

# Set compiler flags to avoid system headers and use only conda environment
export CFLAGS="${CFLAGS} -nostdinc -I${PREFIX}/include -I${BUILD_PREFIX}/include"
export CPPFLAGS="${CPPFLAGS} -nostdinc -I${PREFIX}/include -I${BUILD_PREFIX}/include"

# Add Python and numpy include paths
export CFLAGS="${CFLAGS} -I${BUILD_PREFIX}/include/python${PY_VER} -I${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/numpy/_core/include/"

# Ensure libheif is found
export CFLAGS="${CFLAGS} -I${PREFIX}/include/libheif"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"

# Install the package
${PYTHON} -m pip install . -vvv --no-deps