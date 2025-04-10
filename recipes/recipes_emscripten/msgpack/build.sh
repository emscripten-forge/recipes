#!/bin/bash
export CXXFLAGS="${CXXFLAGS} -fPIC"

${PYTHON} -m pip install . --no-deps

