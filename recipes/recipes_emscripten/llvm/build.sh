mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# clear LDFLAGS flags because they contain sWASM_BIGINT
export LDFLAGS=""



# Configure step
emcmake cmake ${CMAKE_ARGS} -S ../llvm -B .         \
    -GNinja                                         \
    -DCMAKE_BUILD_TYPE=MinSizeRel                   \
    -DCMAKE_PREFIX_PATH=$PREFIX                     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                  \
    -DLLVM_HOST_TRIPLE=wasm32-unknown-emscripten    \
    -DLLVM_TARGETS_TO_BUILD="WebAssembly"           \
    -DLLVM_INCLUDE_BENCHMARKS=OFF                   \
    -DLLVM_INCLUDE_EXAMPLES=OFF                     \
    -DLLVM_INCLUDE_TESTS=OFF                        \
    -DLLVM_ENABLE_LIBEDIT=OFF                       \
    -DLLVM_ENABLE_PROJECTS="clang;lld"              \
    -DCMAKE_CXX_FLAGS="-Dwait4=__syscall_wait4"

# Build step
ninja

# Install step
ninja install
