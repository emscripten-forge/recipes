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
    -DLLVM_ENABLE_ASSERTIONS=ON                     \
    -DLLVM_INCLUDE_BENCHMARKS=OFF                   \
    -DLLVM_INCLUDE_EXAMPLES=OFF                     \
    -DLLVM_INCLUDE_TESTS=OFF                        \
    -DLLVM_ENABLE_LIBEDIT=OFF                       \
    -DLLVM_ENABLE_PROJECTS="clang;lld"              \
    -DLLVM_ENABLE_THREADS=OFF                       \
    -DLLVM_ENABLE_ZSTD=OFF                          \
    -DLLVM_ENABLE_LIBXML2=OFF                       \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF              \
    -DCLANG_ENABLE_ARCMT=OFF                        \
    -DCLANG_ENABLE_BOOTSTRAP=OFF                    \
    -DCMAKE_CXX_FLAGS="-Dwait4=__syscall_wait4"

# Build step
emmake make -j4

# Install step
emmake make install

# Copy all files with ".wasm" extension to $PREFIX/bin
cp $SRC_DIR/build/bin/*.wasm $PREFIX/bin