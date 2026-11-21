#!/bin/bash
set -e

emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)

export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"
# The x86 SIMD engines call CPUID, which is undefined for wasm; use the scalar engines.
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake -Dnanobind_DIR=${NANOBIND_CMAKE_DIR} -DWITH_CR32S=OFF -DWITH_CR64S=OFF"

$PYTHON -m pip install . ${PIP_ARGS}
