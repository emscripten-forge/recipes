#!/bin/bash

set -euxo pipefail

emcmake cmake -S "${SRC_DIR}/llvm" -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DLLVM_HOST_TRIPLE=wasm32-unknown-emscripten \
  -DLLVM_TARGETS_TO_BUILD=WebAssembly \
  -DLLVM_DISTRIBUTION_COMPONENTS="llvm-driver;llvm-readobj;llvm-nm;llvm-size;llvm-cxxfilt" \
  -DLLVM_TOOL_LLVM_DRIVER_BUILD=ON \
  -DLLVM_BUILD_UTILS=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_THREADS=OFF \
  -DLLVM_ENABLE_PIC=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_NATIVE_TOOL_DIR="${BUILD_PREFIX}/bin" \
  -DLLVM_TABLEGEN="${BUILD_PREFIX}/bin/llvm-tblgen" \
  -DCMAKE_C_FLAGS="${EMCC_CFLAGS} -mtail-call" \
  -DCMAKE_CXX_FLAGS="${EMCC_CFLAGS} -mtail-call -Dwait4=__syscall_wait4" \
  -DCMAKE_EXE_LINKER_FLAGS="-O2 -fwasm-exceptions -sMODULARIZE=1 -sEXPORT_ES6=1 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB -sTOTAL_STACK=8MB -sEXIT_RUNTIME=1 -sEXPORTED_RUNTIME_METHODS=FS"

emmake make -C build llvm-driver -j"${CPU_COUNT:-4}"

install -d "${PREFIX}/bin"
install -m 644 build/bin/llvm.js "${PREFIX}/bin/llvm.js"
install -m 644 build/bin/llvm.wasm "${PREFIX}/bin/llvm.wasm"
