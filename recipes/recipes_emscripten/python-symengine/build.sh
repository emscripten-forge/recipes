#!/bin/bash

cp $RECIPE_DIR/CMakeLists.txt $SRC_DIR

${PYTHON} -m pip install .
