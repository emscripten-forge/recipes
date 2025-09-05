#!/bin/bash

# Set compiler flags to avoid system headers and use only conda environment
export CFLAGS="${CFLAGS} -I${PREFIX}/include"
export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"

# Ensure libheif is found
export CFLAGS="${CFLAGS} -I${PREFIX}/include/libheif"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"

# Install the package
${PYTHON} -m pip install . -vvv --no-deps