mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# clear LDFLAGS flags because they contain sWASM_BIGINT
export LDFLAGS=""


# Configure step
emcmake cmake ${CMAKE_ARGS} -S ../llvm -B .         \
    -DCMAKE_BUILD_TYPE=MinSizeRel                   \
    -DCMAKE_PREFIX_PATH=$PREFIX                     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                  \
    -DLLVM_HOST_TRIPLE=wasm32-unknown-emscripten    \
    -DLLVM_TARGETS_TO_BUILD="WebAssembly"           \
    -DLLVM_INCLUDE_BENCHMARKS=OFF                   \
    -DLLVM_INCLUDE_EXAMPLES=OFF                     \
    -DLLVM_INCLUDE_TESTS=OFF                        \
    -DLLVM_ENABLE_LIBEDIT=OFF                       \
    -DLLVM_ENABLE_PROJECTS="clang;" \
    -DLLVM_ENABLE_RUNTIMES="libcxx" \
    -DCMAKE_CXX_FLAGS="-Dwait4=__syscall_wait4"     \
    -DCMAKE_CXX_FLAGS="-isystem $EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/cache/sysroot/include" \
    -DLIBCXXABI_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBCXX_HAS_ATOMIC_LIB=OFF \
    -DHAVE_CXX_ATOMICS64_WITHOUT_LIB=True \
    -DHAVE_CXX_ATOMICS_WITHOUT_LIB=True

# Build step
emmake make VERBOSE=1 -j${CPU_COUNT}

# Install step
emmake make install