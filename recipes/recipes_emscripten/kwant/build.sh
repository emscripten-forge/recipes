#!/bin/bash
export LIBRARY_PATH="${PREFIX}/lib"
export LD_LIBRARY_PATH="${BUILD_PREFIX}/lib"

$PYTHON setup.py build --cython
$PYTHON setup.py install
