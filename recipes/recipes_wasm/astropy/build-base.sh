#!/bin/bash


DISABLED=-Wno-incompatible-function-pointer-types

sed -i 's\from .tests.runner import TestRunner\# from .tests.runner import TestRunner\g' astropy/__init__.py
sed -i 's\test = TestRunner\# test = TestRunner\g' astropy/__init__.py

sed -i 's\__citation__ =\# __citation__ =\g' astropy/__init__.py


export CFLAGS="$CFLAGS     $DISABLED"
export CXXFLAGS="$CXXFLAGS $DISABLED"


export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python$PY_VER/site-packages/numpy/_core/include/"

${PYTHON}  -m pip install . --no-deps  -vvv
