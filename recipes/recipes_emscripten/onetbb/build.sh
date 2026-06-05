#!/bin/bash
set -exuo pipefail

# Set default values for potentially unset variables
EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
EM_FORGE_SIDE_MODULE_LDFLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"
CFLAGS="${CFLAGS:-}"
CXXFLAGS="${CXXFLAGS:-}"
LDFLAGS="${LDFLAGS:-}"

# Disable ucontext-based resumable tasks — ucontext symbols
# (getcontext/makecontext/swapcontext) are not linkable on WASM.
# This forces oneTBB to use pthread-based coroutines instead.
export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -D__TBB_RESUMABLE_TASKS_USE_THREADS=1"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -D__TBB_RESUMABLE_TASKS_USE_THREADS=1"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

mkdir -p build
cd build

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DBUILD_SHARED_LIBS=OFF \
    -DTBB_STRICT=OFF \
    -DTBB_DISABLE_HWLOC_AUTOMATIC_SEARCH=ON \
    -DTBB_EXAMPLES=OFF \
    -DTBB_TEST=OFF \
    -DTBB4PY_BUILD=OFF \
    -DTBBMALLOC_BUILD=ON \
    -DTBBMALLOC_PROXY_BUILD=ON \
    -DTBB_INSTALL=ON \
    -DCMAKE_CXX_FLAGS="-Wno-unused-command-line-argument ${CXXFLAGS}" \
    ..

ninja install

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
