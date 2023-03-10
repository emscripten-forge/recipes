#!/usr/bin/env bash

# Setup toolchain
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
export CMAKE_ARGS="${CMAKE_ARGS} -DEMSCRIPTEN=1 -DCMAKE_TOOLCHAIN_FILE=${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

python -m pip install . -vv
