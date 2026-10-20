#!/bin/bash
set -exuo pipefail

# Set default values for potentially unset variables
EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
EM_FORGE_SIDE_MODULE_LDFLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"
CFLAGS="${CFLAGS:-}"
CXXFLAGS="${CXXFLAGS:-}"
LDFLAGS="${LDFLAGS:-}"

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

mkdir -p build
cd build

emcmake cmake -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DXNNPACK_LIBRARY_TYPE=static \
    -DXNNPACK_BUILD_TESTS=OFF \
    -DXNNPACK_BUILD_BENCHMARKS=OFF \
    -DXNNPACK_BUILD_ALL_MICROKERNELS=OFF \
    -DXNNPACK_USE_SYSTEM_LIBS=OFF \
    -DXNNPACK_ENABLE_ASSEMBLY=OFF \
    -DXNNPACK_ENABLE_KLEIDIAI=OFF \
    ..

ninja install

# XNNPACK does not install a CMake config file, so install our custom one
# for downstream consumers using find_package(XNNPACK CONFIG).
mkdir -p "${PREFIX}/lib/cmake/xnnpack"
cp "${RECIPE_DIR}/XNNPACKConfig.cmake" "${PREFIX}/lib/cmake/xnnpack/"

# Remove .la files if present
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
