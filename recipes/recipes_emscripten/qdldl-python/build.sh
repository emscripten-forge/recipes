#!/usr/bin/env bash
set -euxo pipefail

# Build the pybind11 extension and qdldlamd as Emscripten SIDE_MODULE shared
# libraries against host libqdldl (see feedstock patches + 0005).
FLAGS="-fPIC -sWASM_BIGINT -sSIDE_MODULE=1"
export CFLAGS="${CFLAGS:-} ${FLAGS}"
export CXXFLAGS="${CXXFLAGS:-} ${FLAGS}"
export LDFLAGS="${LDFLAGS:-} -sSIDE_MODULE=1 -sWASM_BIGINT -L${PREFIX}/lib"

# Ensure the cmake step inside setup.py can find_package(qdldl) and enable
# shared SIDE_MODULE builds via overwriteProp.cmake.
export CMAKE_PREFIX_PATH="${PREFIX}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export CMAKE_ARGS="${CMAKE_ARGS:-} -DCMAKE_PREFIX_PATH=${PREFIX} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"

${PYTHON} -m pip install . --no-deps --no-build-isolation -vv
