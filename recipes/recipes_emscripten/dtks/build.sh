#!/bin/bash
set -e

# add nanobind dir to cmake args
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"


export CMAKE_ARGS

#!/bin/bash
${PYTHON} -m pip  install . --prefix="$PREFIX"
