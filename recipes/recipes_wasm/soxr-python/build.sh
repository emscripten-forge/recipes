#!/bin/bash
set -e

NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)
CMAKE_ARGS="${CMAKE_ARGS} -Dnanobind_DIR=${NANOBIND_CMAKE_DIR}"
# Use the bundled libsoxr (newer than the 0.1.3 release in libsoxr-static,
# which traps with "function signature mismatch" in wasm). The SIMD engines
# use x86 CPUID detection, so build only the plain C engines.
CMAKE_ARGS="${CMAKE_ARGS} -DWITH_CR32S=OFF -DWITH_CR64S=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
# build the extension as an emscripten side module
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"
# point FindPython at the (cross) target python
CMAKE_ARGS="${CMAKE_ARGS} -DPython_EXECUTABLE=${PYTHON}"
CMAKE_ARGS="${CMAKE_ARGS} -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER}"
CMAKE_ARGS="${CMAKE_ARGS} -DPython_LIBRARY=${PREFIX}/lib/libpython${PY_VER}.a"
export CMAKE_ARGS

${PYTHON} -m pip install . --prefix="$PREFIX" --no-deps --no-build-isolation -vv
