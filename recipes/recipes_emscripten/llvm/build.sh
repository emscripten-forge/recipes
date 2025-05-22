#!/bin/bash

mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# clear LDFLAGS flags because they contain sWASM_BIGINT
export LDFLAGS=""

ls -la $BUILD_PREFIX/bin

# Configure step
emcmake cmake ${CMAKE_ARGS} -S ../llvm -B .         \
    -DCMAKE_BUILD_TYPE=Release                      \
    -DCMAKE_PREFIX_PATH=$PREFIX                     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                  \
    -DLLVM_HOST_TRIPLE=wasm32-unknown-emscripten    \
    -DLLVM_TARGETS_TO_BUILD="WebAssembly"           \
    -DLLVM_ENABLE_ASSERTIONS=ON                     \
    -DLLVM_ENABLE_EH=ON                             \
    -DLLVM_ENABLE_RTTI=ON                           \
    -DLLVM_INCLUDE_BENCHMARKS=OFF                   \
    -DLLVM_INCLUDE_EXAMPLES=OFF                     \
    -DLLVM_INCLUDE_TESTS=OFF                        \
    -DLLVM_ENABLE_LIBEDIT=OFF                       \
    -DLLVM_ENABLE_PROJECTS="clang;lld"              \
    -DLLVM_ENABLE_THREADS=OFF                       \
    -DLLVM_ENABLE_ZSTD=OFF                          \
    -DLLVM_ENABLE_LIBXML2=OFF                       \
    -DLLVM_BUILD_TOOLS=OFF                          \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF              \
    -DCLANG_ENABLE_ARCMT=OFF                        \
    -DCLANG_ENABLE_BOOTSTRAP=OFF                    \
    -DCLANG_BUILD_TOOLS=OFF                         \
    -DCMAKE_CXX_FLAGS="-Dwait4=__syscall_wait4 -fexceptions" \
    -DLLVM_TABLEGEN=$BUILD_PREFIX/bin/llvm-tblgen \
    -DCLANG_TABLEGEN=$BUILD_PREFIX/bin/clang-tblgen 

# Build and Install step
emmake make clangInterpreter lldWasm -j16 install
