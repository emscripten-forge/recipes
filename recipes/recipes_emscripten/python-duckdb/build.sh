#!/bin/bash

export PYBIND11_INCLUDE_DIR=$PREFIX/include
${PYTHON} -m pip install . ${PIP_ARGS}
