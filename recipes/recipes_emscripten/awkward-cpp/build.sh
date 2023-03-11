#!/usr/bin/env bash

# Setup toolchain
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"
export CMAKE_ARGS="${CMAKE_ARGS} -DEMSCRIPTEN=1 -DCMAKE_TOOLCHAIN_FILE=${toolchain_path}"

python -m pip install . -vv
