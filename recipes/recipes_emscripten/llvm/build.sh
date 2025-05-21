mkdir native_build
cd native_build
cmake -DLLVM_ENABLE_PROJECTS=clang -DLLVM_TARGETS_TO_BUILD=host -DCMAKE_BUILD_TYPE=Release ../llvm/
cmake --build . --target llvm-tblgen clang-tblgen --parallel $(nproc --all)
export NATIVE_DIR=$PWD/bin/
cd ..

mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# clear LDFLAGS flags because they contain sWASM_BIGINT
export LDFLAGS=""

# Configure step
emcmake cmake ${CMAKE_ARGS} -S ../llvm -B .         \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_HOST_TRIPLE=wasm32-unknown-emscripten \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_TARGETS_TO_BUILD="WebAssembly" \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
    -DCLANG_ENABLE_ARCMT=OFF \
    -DCLANG_ENABLE_BOOTSTRAP=OFF \
    -DCMAKE_CXX_FLAGS="-Dwait4=__syscall_wait4 -fexceptions" \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_ENABLE_THREADS=OFF \
    -DLLVM_BUILD_TOOLS=OFF \
    -DLLVM_ENABLE_LIBPFM=OFF \
    -DCLANG_BUILD_TOOLS=OFF \
    -DLLVM_TABLEGEN=$NATIVE_DIR/llvm-tblgen \
    -DCLANG_TABLEGEN=$NATIVE_DIR/clang-tblgen \

# Build and Install step
emmake make clangInterpreter lldWasm -j16 install
