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

# Generate config.h (normally done by flang-rt/CMakeLists.txt)
find_package(Backtrace)
set(HAVE_BACKTRACE ${Backtrace_FOUND})
set(BACKTRACE_HEADER ${Backtrace_HEADER})
# wasm32/linux: strerror_r exists, strerror_s (Windows) does not
set(HAVE_STRERROR_R 1)
set(HAVE_DECL_STRERROR_S 0)
configure_file("${FLANG_RT_SOURCE_DIR}/cmake/config.h.cmake.in" config.h)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_subdirectory("${FLANG_RT_SOURCE_DIR}/lib/runtime" runtime_build)
CMAKEOF

emcmake cmake -S _wrapper -B _fbuild_runtime -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX
$(which cmake) --build _fbuild_runtime
$(which cmake) --build _fbuild_runtime --target install


# Build libFortranDecimal.a
# In LLVM 21, flang/lib/Decimal uses add_flang_library which pulls in the
# entire LLVM cmake infrastructure. For just 2 source files, build directly.
mkdir -p _wrapper_decimal
cat > _wrapper_decimal/CMakeLists.txt << 'CMAKEOF'
cmake_minimum_required(VERSION 3.20)
project(flang-decimal C CXX)

set(FLANG_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flang")
include_directories("${FLANG_SOURCE_DIR}/include")

add_library(FortranDecimal STATIC
    "${FLANG_SOURCE_DIR}/lib/Decimal/binary-to-decimal.cpp"
    "${FLANG_SOURCE_DIR}/lib/Decimal/decimal-to-binary.cpp"
)

install(TARGETS FortranDecimal ARCHIVE DESTINATION lib)
CMAKEOF

emcmake cmake -S _wrapper_decimal -B _fbuild_decimal -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX
$(which cmake) --build _fbuild_decimal
$(which cmake) --build _fbuild_decimal --target install
