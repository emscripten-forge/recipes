#!/bin/bash

PYODIDE_PACKED=$RECIPE_DIR/scipy-1.11.1-cp311-cp311-emscripten_3_1_45_wasm32.whl
# unzip 
unzip $PYODIDE_PACKED

# copy complete folder scipy to side-packages
mkdir -p $PREFIX/lib/python3.11/site-packages
cp -r scipy $PREFIX/lib/python3.11/site-packages
cp -r scipy-1.11.1.dist-info $PREFIX/lib/python3.11/site-packages