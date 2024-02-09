#!/bin/bash

# Removing this warning will not be needed after the next pybind11 release
export CPPFLAGS="-Wno-deprecated-literal-operator"

${PYTHON} -m pip install . -vvv --no-deps
