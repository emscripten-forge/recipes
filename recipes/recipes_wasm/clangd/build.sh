#!/usr/bin/env bash
set -euo pipefail

case "${target_platform}" in
  emscripten-wasm32) arch=wasm32; memory_flags= ;;
  emscripten-wasm64) arch=wasm64; memory_flags=-sMEMORY64=1 ;;
  *) echo "Unsupported target platform: ${target_platform}" >&2; exit 1 ;;
esac

native="${BUILD_PREFIX}/bin"
flags="-O2 -g0 -pthread -mno-tail-call -fwasm-exceptions ${memory_flags}"
link_flags="${LDFLAGS:-} ${flags} -sPROXY_TO_PTHREAD=1 -sPTHREAD_POOL_SIZE=8"
link_flags+=" -sPTHREAD_POOL_SIZE_STRICT=0 -sENVIRONMENT=worker"
link_flags+=" -sMODULARIZE=1 -sEXPORT_ES6=1 -sEXPORT_NAME=createClangdModule"
link_flags+=" -sINVOKE_RUN=0 -sEXIT_RUNTIME=0 -sALLOW_MEMORY_GROWTH=1"
link_flags+=" -sINITIAL_MEMORY=256MB -sMAXIMUM_MEMORY=2GB -sSTACK_SIZE=8MB"
link_flags+=" -sEXPORTED_RUNTIME_METHODS=FS,callMain --js-library=${RECIPE_DIR}/stdin.js"

# LLVM and Clang are internal pthread-enabled dependencies, not package outputs.
# CMAKE_ARGS supplies the compiler toolchain and matching wasm32/wasm64 target.
emcmake cmake ${CMAKE_ARGS} -G "Unix Makefiles" -S "${SRC_DIR}/llvm" -B build \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DCMAKE_C_FLAGS="${CFLAGS:-} ${EMCC_CFLAGS:-} ${flags}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS:-} ${flags} -Dwait4=__syscall_wait4" \
  -DCMAKE_EXE_LINKER_FLAGS="${link_flags}" \
  -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra' \
  -DLLVM_TABLEGEN="${native}/llvm-tblgen" \
  -DCLANG_TABLEGEN="${native}/clang-tblgen" \
  -DLLVM_HOST_TRIPLE="${arch}-unknown-emscripten" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="${arch}-unknown-emscripten" \
  -DLLVM_TARGETS_TO_BUILD=WebAssembly -DLLVM_ENABLE_THREADS=ON \
  -DLLVM_APPEND_VC_REV=OFF \
  -DBUILD_SHARED_LIBS=OFF -DLLVM_ENABLE_PIC=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_DOCS=OFF \
  -DLLVM_ENABLE_BACKTRACES=OFF -DLLVM_ENABLE_UNWIND_TABLES=OFF \
  -DLLVM_ENABLE_CRASH_OVERRIDES=OFF -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_ZSTD=OFF -DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_CURL=OFF \
  -DCLANG_ENABLE_ARCMT=OFF -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
  -DCLANGD_BUILD_XPC=OFF \
  -DCLANGD_DECISION_FOREST=OFF -DCLANGD_TIDY_CHECKS=OFF \
  -DCLANG_TIDY_ENABLE_STATIC_ANALYZER=OFF \
  -DCLANG_TIDY_ENABLE_QUERY_BASED_CUSTOM_CHECKS=OFF

emmake make -C build -j"${CPU_COUNT:-2}" clangd
mkdir -p "${PREFIX}/bin"
install -m 644 build/bin/clangd.js build/bin/clangd.wasm "${PREFIX}/bin/"
