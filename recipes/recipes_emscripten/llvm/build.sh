
mkdir native_build
cd native_build
export TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE
export CROSSCOMPILING_EMULATOR=$CMAKE_CROSSCOMPILING_EMULATOR
export CMAKE_TOOLCHAIN_FILE=""
export CMAKE_CROSSCOMPILING_EMULATOR=""
cmake -DLLVM_ENABLE_PROJECTS=clang -DLLVM_TARGETS_TO_BUILD=host -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER="clang" -DCMAKE_CXX_COMPILER="clang++" ../llvm/
make llvm-tblgen clang-tblgen -j$(nproc --all)
export NATIVE_DIR=$PWD/bin/
cd ..


mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX
export CMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE
export CMAKE_CROSSCOMPILING_EMULATOR=$CROSSCOMPILING_EMULATOR

# clear LDFLAGS flags because they contain sWASM_BIGINT
export LDFLAGS=""

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
    -DLLVM_TABLEGEN=$NATIVE_DIR/llvm-tblgen         \
    -DCLANG_TABLEGEN=$NATIVE_DIR/clang-tblgen       \

# Build and Install step
emmake make clangInterpreter lldWasm -j16 install
