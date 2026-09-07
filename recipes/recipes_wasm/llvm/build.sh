#!/bin/bash

set -euxo pipefail

case "${target_platform}" in
  emscripten-wasm32)
    llvm_host_triple="wasm32-unknown-emscripten"
    ;;
  emscripten-wasm64)
    llvm_host_triple="wasm64-unknown-emscripten"
    ;;
  *)
    echo "Unsupported target platform: ${target_platform}" >&2
    exit 1
    ;;
esac

export CMAKE_PREFIX_PATH="${PREFIX}"
export CMAKE_SYSTEM_PREFIX_PATH="${PREFIX}"

emcmake cmake -S "${SRC_DIR}/llvm" -B build \
    -DCMAKE_BUILD_TYPE=Release                      \
    -DCMAKE_PREFIX_PATH="${PREFIX}"                 \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}"              \
    -DLLVM_HOST_TRIPLE="${llvm_host_triple}"        \
    -DLLVM_TARGETS_TO_BUILD="WebAssembly;X86;AArch64" \
    -DLLVM_INCLUDE_BENCHMARKS=OFF                   \
    -DLLVM_INCLUDE_EXAMPLES=OFF                     \
    -DLLVM_INCLUDE_TESTS=OFF                        \
    -DLLVM_INCLUDE_DOCS=OFF                         \
    -DLLVM_ENABLE_LIBEDIT=OFF                       \
    -DLLVM_ENABLE_PROJECTS="clang;lld"              \
    -DLLVM_DISTRIBUTION_COMPONENTS="cmake-exports;llvm-headers;llvm-libraries;clang-cmake-exports;clang-headers;clang-resource-headers;clang-libraries;lld-cmake-exports;lld-headers;lldCommon;lldWasm" \
    -DLLVM_ENABLE_THREADS=OFF                       \
    -DLLVM_ENABLE_PIC=ON                            \
    -DLLVM_ENABLE_ZSTD=OFF                          \
    -DLLVM_ENABLE_LIBXML2=OFF                       \
    -DLLVM_BUILD_TOOLS=OFF                          \
    -DLLVM_BUILD_UTILS=OFF                          \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF              \
    -DCLANG_ENABLE_OBJC_REWRITER=OFF                \
    -DCLANG_ENABLE_BOOTSTRAP=OFF                    \
    -DCLANG_BUILD_TOOLS=OFF                         \
    -DLLD_BUILD_TOOLS=OFF                           \
    -DCMAKE_C_FLAGS="${EMCC_CFLAGS} -mtail-call"    \
    -DCMAKE_CXX_FLAGS="${EMCC_CFLAGS} -mtail-call -Dwait4=__syscall_wait4" \
    -DLLVM_NATIVE_TOOL_DIR="${BUILD_PREFIX}/bin"

emmake make -C build -j"${CPU_COUNT:-2}" install-distribution
