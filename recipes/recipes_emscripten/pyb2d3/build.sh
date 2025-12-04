#!/bin/bash
set -e

# add nanobind dir to cmake args
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"
CMAKE_ARGS="${CMAKE_ARGS} -DFETCH_BOX2D=OFF" 
CMAKE_ARGS="${CMAKE_ARGS} -DPYB2D3_NO_THREADING=ON" 

export CFLAGS="$CFLAGS -sWASM_BIGINT -fexceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -fexceptions"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -fexceptions"

export CMAKE_ARGS

#!/bin/bash
${PYTHON} -m pip  install . --prefix="$PREFIX"
