#!/bin/bash


DISABLED=-Wno-incompatible-function-pointer-types

export CFLAGS="$CFLAGS     $DISABLED"
export CXXFLAGS="$CXXFLAGS $DISABLED"

${PYTHON}  -m pip install . --no-deps  -vvv