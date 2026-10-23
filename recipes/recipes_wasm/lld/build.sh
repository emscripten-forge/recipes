#!/bin/bash
set -euxo pipefail

# Emscripten 6.0.8 predates LLVM's byval tail-call fix (#227491).
# Match the LLVM recipe until the SDK includes that fix.
emcmake cmake ${CMAKE_ARGS} -S "${SRC_DIR}/lld" -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DLLVM_DIR="${PREFIX}/lib/cmake/llvm" \
    -DLLVM_DISTRIBUTIONS=Static \
    -DLLVM_Static_DISTRIBUTION_COMPONENTS="lld-headers;lld-cmake-exports;lld-static-cmake-exports;lldCommon;lldWasm" \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLD_BUILD_TOOLS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="${CFLAGS:-} ${EMCC_CFLAGS} -mno-tail-call" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS} -mno-tail-call -Dwait4=__syscall_wait4" \
    -DLLVM_TABLEGEN_EXE="${BUILD_PREFIX}/bin/llvm-tblgen"

# Standalone LLD provides component install targets rather than distribution targets.
emmake make -C build -j"${CPU_COUNT:-2}" \
    install-lldCommon install-lldWasm install-lld-headers \
    install-lld-cmake-exports install-lld-static-cmake-exports
