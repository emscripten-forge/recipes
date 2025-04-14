#!/bin/bash


CMAKE_ARGS="-DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake"
${PYTHON} -m pip install .
