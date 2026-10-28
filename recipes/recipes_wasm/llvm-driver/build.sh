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

# Emscripten 6.0.8 predates LLVM's byval tail-call fix (#227491),
# so tail calls stay disabled (same as the llvm recipe).
emcmake cmake ${CMAKE_ARGS} -S "${SRC_DIR}/llvm" -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DLLVM_HOST_TRIPLE="${llvm_host_triple}" \
  -DLLVM_TARGETS_TO_BUILD=WebAssembly \
  -DLLVM_DISTRIBUTION_COMPONENTS="llvm-driver;llvm-readobj;llvm-nm;llvm-size;llvm-cxxfilt;llvm-ar;llvm-objdump;llvm-objcopy" \
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
  -DCMAKE_C_FLAGS="${CFLAGS:-} ${EMCC_CFLAGS} -mno-tail-call" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS} -mno-tail-call -Dwait4=__syscall_wait4" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS:-} -O2 -mno-tail-call -fwasm-exceptions -sMODULARIZE=1 -sEXPORT_ES6=1 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB -sSTACK_SIZE=8MB -sEXIT_RUNTIME=1 -sEXPORTED_RUNTIME_METHODS=FS"

emmake make -C build llvm-driver -j"${CPU_COUNT:-4}"

install -d "${PREFIX}/bin"
install -m 644 build/bin/llvm.js "${PREFIX}/bin/llvm.js"
install -m 644 build/bin/llvm.wasm "${PREFIX}/bin/llvm.wasm"
