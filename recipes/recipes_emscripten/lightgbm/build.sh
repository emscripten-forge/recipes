#!/usr/bin/env bash
set -e

# Setup toolchain
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

# CMakeLists.txt unconditionally adds -pthread on UNIX, which makes the module
# require shared memory and fails to load in the non-threaded wasm runtime.
sed -i 's/ -pthread -Wextra/ -Wextra/' CMakeLists.txt

# Setup build arguments
export CMAKE_GENERATOR="Unix Makefiles"
export CMAKE_ARGS="${CMAKE_ARGS} -DEMSCRIPTEN=1 -DUSE_OPENMP=OFF -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"

$PYTHON -m pip install . -vv
