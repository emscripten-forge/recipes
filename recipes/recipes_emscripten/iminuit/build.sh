#!/usr/bin/env bash

# Setup toolchain
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

# Setup build arguments
export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"   
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"

python -m pip install . -vv
