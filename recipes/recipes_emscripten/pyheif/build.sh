#!/bin/bash

sed -i "s@include_dirs = \[@include_dirs = ['\\${CONDA_EMSDK_DIR}/include', @" libheif/libheif_build.py
sed -i "s@library_dirs = \[@library_dirs = ['\\${CONDA_EMSDK_DIR}/lib', @" libheif/libheif_build.py

${PYTHON} -m pip install . -vv