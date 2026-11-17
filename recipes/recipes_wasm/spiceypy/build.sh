#!/usr/bin/env bash
set -ex

# Setup toolchain
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

# CSPICE (via cspice-cmake-spiceypy) is fetched and built in-tree by
# SpiceyPy's CMakeLists.txt and vendored into site-packages/spiceypy.libs/
export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_TOOLCHAIN_FILE=${toolchain_path}"

${PYTHON} -m pip install . --no-deps -vv
