#!/usr/bin/env bash
set -e

# Setup toolchain
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

# Build the pyclingo MODULE as a wasm side module (see overwriteProp.cmake)
export CMAKE_ARGS="${CMAKE_ARGS} -DEMSCRIPTEN=1 -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"

$PYTHON -m pip install . -vv
