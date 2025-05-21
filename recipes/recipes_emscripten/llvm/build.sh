#!/bin/bash

unset cmake

unset CONDA_FORGE_EMSCRIPTEN_ACTIVATED
unset PY_SIDE_LD_FLAGV
unset EM_FORGE_OPTFLAGS
unset EM_FORGE_DBGFLAGS
unset EM_FORGE_LDFLAGS_BASE
unset EM_FORGE_CFLAGS_BASE
unset EM_FORGE_SIDE_MODULE_LDFLAGS
unset EM_FORGE_SIDE_MODULE_CFLAGS

# restore
export LDFLAGS=$EM_OLD_LDFLAGS
export CFLAGS=$EM_OLD_CFLAGS

unset EM_OLD_LDFLAGS
unset EM_OLD_CFLAGS

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


export EM_OLD_LDFLAGS=$LDFLAGS
export EM_OLD_CFLAGS=$CFLAGS


export CONDA_FORGE_EMSCRIPTEN_ACTIVATED=1

if [ -z ${BUILD_PREFIX+x} ]; then
    export EMSDK_PYTHON=${CONDA_PREFIX}/bin/python3
    export PYTHON=${CONDA_PREFIX}/bin/python3
else
    export EMSDK_PYTHON=${BUILD_PREFIX}/bin/python3
    export PYTHON=${BUILD_PREFIX}/bin/python3
fi

CONDA_EMSDK_DIR=$CONDA_PREFIX/opt/emsdk

export EMSCRIPTEN_VERSION=$PKG_VERSION
export EMSCRIPTEN_FORGE_EMSDK_DIR=$CONDA_EMSDK_DIR

# clear all prexisting cmake args / CC / CXX / AR / RANLIB
export CC="emcc"
export CXX="em++"
export AR="emar"
export RANLIB="emranlib"

export CMAKE_ARGS=""

# set the emscripten toolchain
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=$CONDA_EMSDK_DIR/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"

# conda prefix path
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_PREFIX_PATH=$PREFIX"

# install prefix
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=$PREFIX"

# find root path mode package
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON"

# fpic
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true"

cmake () {
    emcmake cmake "$@"
}


# basics
export EM_FORGE_OPTFLAGS="-O2"
export EM_FORGE_DBGFLAGS="-g0"

# basics ld
export EM_FORGE_LDFLAGS_BASE="-s WASM=1 -sWASM_BIGINT -L${PREFIX}/lib"
export EM_FORGE_LDFLAGS_BASE="${EM_FORGE_OPTFLAGS} ${EM_FORGE_DBGFLAGS} ${EM_FORGE_LDFLAGS_BASE}"

# basics cflags
export EM_FORGE_CFLAGS_BASE="-fPIC"
export EM_FORGE_CFLAGS_BASE="${EM_FORGE_OPTFLAGS} ${EM_FORGE_DBGFLAGS} ${EM_FORGE_CFLAGS_BASE}"

# side module
export EM_FORGE_SIDE_MODULE_LDFLAGS="${EM_FORGE_LDFLAGS_BASE} -s SIDE_MODULE=1"
export EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_CFLAGS_BASE} -I${PREFIX}/include"


export LDFLAGS="${EM_FORGE_LDFLAGS_BASE} ${LDFLAGS}"
export CFLAGS="${EM_FORGE_CFLAGS_BASE} ${CFLAGS}"


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
