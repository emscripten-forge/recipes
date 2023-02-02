#!/bin/bash

cp $RECIPE_DIR/patches/erfaversion.c liberfa/erfa/src/erfaversion.c

${PYTHON} erfa_generator.py

export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python$PY_VER/site-packages/numpy/core/include/"
${PYTHON} -m pip  install .
