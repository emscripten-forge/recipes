#!/bin/bash
set -e

# add nanobind dir to cmake args
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"
CMAKE_ARGS="${CMAKE_ARGS} -DFETCH_RAYLIB=OFF"


# raylib_LIBRARY
CMAKE_ARGS="${CMAKE_ARGS} -Draylib_LIBRARY=$PREFIX/lib/libraylib.a"
CMAKE_ARGS="${CMAKE_ARGS} -Draylib_INCLUDE_DIR=$PREFIX/include"

# -DBUILD_WASM_HOST=OFF
CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_WASM_HOST=OFF"

export CFLAGS="$CFLAGS -sWASM_BIGINT -fexceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -fexceptions"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -fexceptions"

export CMAKE_ARGS

#!/bin/bash
${PYTHON} -m pip  install . --prefix="$PREFIX"
