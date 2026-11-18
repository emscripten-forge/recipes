#!/bin/bash
set -exuo pipefail

# Set default values for potentially unset variables
EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
EM_FORGE_SIDE_MODULE_LDFLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"
CFLAGS="${CFLAGS:-}"
CXXFLAGS="${CXXFLAGS:-}"
LDFLAGS="${LDFLAGS:-}"

# -DEMSCRIPTEN=1: Emscripten 6 no longer defines the deprecated EMSCRIPTEN
# macro on the command line, but oneTBB still checks it in governor.cpp and
# global_control.cpp (stack base and default stack size).
#
# No -pthread: the wasm runtime is single-threaded. sysconf then reports 1
# CPU, so oneTBB creates a workerless arena and runs tasks on the calling
# thread. Emscripten's libc provides single-threaded stubs for the pthread
# symbols oneTBB references (mutexes, TLS, worker launcher).
#
# -D__TBB_RESUMABLE_TASKS_USE_THREADS=1: Emscripten declares
# getcontext/makecontext/swapcontext but does not implement them, so the
# default ucontext-based resumable-task coroutines would fail to link.
export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -DEMSCRIPTEN=1 -D__TBB_RESUMABLE_TASKS_USE_THREADS=1"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -DEMSCRIPTEN=1 -D__TBB_RESUMABLE_TASKS_USE_THREADS=1"
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
