#!/usr/bin/env bash
set -euxo pipefail

export CMAKE_GENERATOR="Unix Makefiles"
export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"
export CMAKE_TOOLCHAIN_FILE="${BUILD_PREFIX}/opt/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"
# Keep the dylink metadata removed by pybind11's Release-mode stripping.
export CMAKE_BUILD_TYPE=RelWithDebInfo

"${PYTHON}" -m pip install . --no-deps --no-build-isolation --no-compile -v
