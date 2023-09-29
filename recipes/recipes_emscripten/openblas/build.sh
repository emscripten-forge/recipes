#!/bin/bash

PYODIDE_PACKED=$RECIPE_DIR/openblas-0.3.23.zip
# unzip 
unzip $PYODIDE_PACKED
# copy libopenblas.so to 
mkdir -p $PREFIX/lib
cp libopenblas.so $PREFIX/lib