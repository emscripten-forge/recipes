#!/usr/bin/env bash

set -eux

export FLAGS="-DNDEBUG -fPIC -sWASM_BIGINT -s SIDE_MODULE=1 -fwasm-exceptions"
export CFLAGS="${CFLAGS:-} ${FLAGS}"
export CXXFLAGS="${CXXFLAGS:-} ${FLAGS}"
export LDFLAGS="${LDFLAGS:-} -fwasm-exceptions -sWASM_BIGINT"

emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"
export CMAKE_ARGS="${CMAKE_ARGS:-} -DWITH_FORTRAN=OFF -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"

$PYTHON -m pip install . --no-deps --no-build-isolation ${PIP_ARGS} -vv
