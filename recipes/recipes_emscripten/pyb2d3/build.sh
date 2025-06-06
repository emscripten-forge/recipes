#!/bin/bash
set -e

# CUSTOM_FIND_PYTHON=$RECIPE_DIR/FindPython.cmake
# mkdir -p $BUILD_PREFIX/share/cmake-4.0/Modules
# cp $CUSTOM_FIND_PYTHON $BUILD_PREFIX/share/cmake-4.0/Modules/FindPython.cmake



# add nanobind dir to cmake args
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"
CMAKE_ARGS="${CMAKE_ARGS} -DPYB2D3_NO_THREADING=ON" 
export CMAKE_ARGS

#!/bin/bash
${PYTHON} -m pip  install . --prefix="$PREFIX"
