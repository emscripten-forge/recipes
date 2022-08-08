#!/bin/bash

set -x

export PYTHONNOUSERSITE=1

export LLVMLITE_USE_CMAKE=1
export LLVMLITE_SHARED=1

python setup.py build --force
python setup.py install