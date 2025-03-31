#!/bin/bash



# apply all patches in ${RECIPE_DIR}/patches
cat $RECIPE_DIR/patches/*.patch | patch -p1 --verbose 


${PYTHON} -m pip install .
