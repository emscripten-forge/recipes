#!/bin/bash

# Meson finds numpy via pkg-config and numpy.pc
export PKG_CONFIG_PATH=$PREFIX/lib/python$PY_VER/site-packages/numpy/_core/lib/pkgconfig:$PKG_CONFIG_PATH

${PYTHON} -m pip install . -vv --no-binary shapely --no-build-isolation \
    -Csetup-args="--cross-file=$MESON_CROSS_PYTHON_FILE"
