#!/bin/bash

set -ex

export CFLAGS="$CFLAGS -fPIC"
export CXXFLAGS="$CXXFLAGS -fPIC"

# See https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# LLVM 21 moved the runtime from flang/runtime to flang-rt/lib/runtime.
# The subdirectory CMakeLists.txt expects the parent cmake to have set up
# AddFlangRT, install paths, and a flang-rt meta-target. We use a minimal
# wrapper to provide these without pulling in the full LLVM runtimes build.
mkdir -p _wrapper
cat > _wrapper/CMakeLists.txt << 'CMAKEOF'
cmake_minimum_required(VERSION 3.20)
project(flang-rt-runtime C CXX)

set(FLANG_RT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flang-rt")
set(FLANG_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flang")

list(APPEND CMAKE_MODULE_PATH
    "${FLANG_RT_SOURCE_DIR}/cmake/modules"
    "${FLANG_SOURCE_DIR}/cmake/modules"
)

# Provide modules and variables the subdirectory expects from its parent
include(AddFlangRT)
include(AddFlangRTOffload)

set(FLANG_RT_ENABLE_STATIC ON)
set(FLANG_RT_ENABLE_SHARED OFF)

# Install paths — just use lib/ under the prefix
set(FLANG_RT_OUTPUT_RESOURCE_LIB_DIR "${CMAKE_CURRENT_BINARY_DIR}/lib")
set(FLANG_RT_INSTALL_RESOURCE_LIB_PATH "lib")

# Meta-target that add_flangrt_library adds dependencies to
add_custom_target(flang-rt)

add_subdirectory("${FLANG_RT_SOURCE_DIR}/lib/runtime" runtime_build)
CMAKEOF

emcmake cmake -S _wrapper -B _fbuild_runtime -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX
$(which cmake) --build _fbuild_runtime
$(which cmake) --build _fbuild_runtime --target install


# Build libFortranDecimal.a
emcmake cmake -S flang/lib/Decimal -B _fbuild_decimal -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX
$(which cmake) --build _fbuild_decimal
$(which cmake) --build _fbuild_decimal --target install
