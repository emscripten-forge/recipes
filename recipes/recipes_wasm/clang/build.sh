#!/bin/bash
set -euxo pipefail

emcmake cmake ${CMAKE_ARGS} -S "${SRC_DIR}/clang" -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DLLVM_DIR="${PREFIX}/lib/cmake/llvm" \
    -DLLD_DIR="${PREFIX}/lib/cmake/lld" \
    -DLLVM_DISTRIBUTIONS="Static;Interpreter;LibClang;ClangCpp" \
    -DLLVM_Static_DISTRIBUTION_COMPONENTS="clang-cmake-exports;clang-static-cmake-exports;clang-headers;clang-resource-headers;clang-libraries" \
    -DLLVM_Interpreter_DISTRIBUTION_COMPONENTS="clangInterpreter;clang-interpreter-cmake-exports" \
    -DLLVM_LibClang_DISTRIBUTION_COMPONENTS="libclang;clang-libclang-cmake-exports" \
    -DLLVM_ClangCpp_DISTRIBUTION_COMPONENTS="clang-cpp;clang-clangcpp-cmake-exports" \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DCLANG_INCLUDE_DOCS=OFF \
    -DCLANG_BUILD_TOOLS=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
    -DCLANG_ENABLE_OBJC_REWRITER=OFF \
    -DCLANG_ENABLE_BOOTSTRAP=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="${CFLAGS:-} ${EMCC_CFLAGS} -mtail-call" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS} -mtail-call -Dwait4=__syscall_wait4" \
    -DLLVM_TABLEGEN_EXE="${BUILD_PREFIX}/bin/llvm-tblgen" \
    -DCLANG_TABLEGEN="${BUILD_PREFIX}/bin/clang-tblgen"

emmake make -C build -j"${CPU_COUNT:-2}" \
    install-static-distribution install-interpreter-distribution \
    install-libclang-distribution install-clangcpp-distribution
