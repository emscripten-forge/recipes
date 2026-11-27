#!/usr/bin/env bash

set -eux

# Flags follow the Pyodide recipe: no pthreads, no stack traces, no fopen64, plus wasm exceptions.
export FLAGS="-DNDEBUG -fPIC -sWASM_BIGINT -s SIDE_MODULE=1 -fwasm-exceptions -DDMLC_USE_FOPEN64=0 -DDMLC_ENABLE_STD_THREAD=0 -DDMLC_LOG_STACK_TRACE=0"
export CFLAGS="${CFLAGS:-} ${FLAGS}"
export CXXFLAGS="${CXXFLAGS:-} ${FLAGS}"
export LDFLAGS="${LDFLAGS:-} -fwasm-exceptions -sWASM_BIGINT"

emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

# The patched packager reads these extra CMake arguments for the libxgboost build.
export XGBOOST_EXTRA_CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake -DCMAKE_BUILD_TYPE=Release"

$PYTHON -m pip install . --no-deps --no-build-isolation -Cuse_openmp=false ${PIP_ARGS} -vv
