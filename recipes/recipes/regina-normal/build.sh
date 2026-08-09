#!/bin/bash

export CFLAGS="$CFLAGS -fPIC -O3"
export CXXFLAGS="$CXXFLAGS -fPIC -O3"

${PYTHON} setup.py package_assemble
${PYTHON} -m pip install . -vv
