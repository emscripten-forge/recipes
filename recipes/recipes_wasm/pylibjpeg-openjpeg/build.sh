#!/bin/bash
set -euxo pipefail

# build_package.py runs a plain `cmake <openjpeg dir>` (only to generate the
# opj config headers); make that configure for emscripten instead of the
# build machine (otherwise e.g. macOS `-arch` flags end up on emcc)
export CMAKE_TOOLCHAIN_FILE=${BUILD_PREFIX}/opt/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake

${PYTHON} -m pip install . --no-deps --no-build-isolation -vv
