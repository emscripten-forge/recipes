#!/bin/bash
set -x

# set -x

# Make osx work like linux.
sed -i.bak "s/NOT APPLE AND ARG_SONAME/ARG_SONAME/g" llvm/cmake/modules/AddLLVM.cmake
sed -i.bak "s/NOT APPLE AND NOT ARG_SONAME/NOT ARG_SONAME/g" llvm/cmake/modules/AddLLVM.cmake

mkdir build
cd build

# if [[ "$target_platform" == "linux-64" ]]; then
#   CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_USE_INTEL_JITEVENTS=ON"
# fi

# if [[ "$CC_FOR_BUILD" != "" && "$CC_FOR_BUILD" != "$CC" ]]; then
#   CMAKE_ARGS="${CMAKE_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD;-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2;-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,${BUILD_PREFIX}/lib;-DCMAKE_MODULE_LINKER_FLAGS=;-DCMAKE_SHARED_LINKER_FLAGS=;-DCMAKE_STATIC_LINKER_FLAGS=;-DLLVM_INCLUDE_BENCHMARKS=OFF;"
#   CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_HOST_TRIPLE=$(echo $HOST | sed s/conda/unknown/g) -DLLVM_DEFAULT_TARGET_TRIPLE=$(echo $HOST | sed s/conda/unknown/g)"
# fi

# disable -fno-plt due to https://bugs.llvm.org/show_bug.cgi?id=51863 due to some GCC bug
# if [[ "$target_platform" == "linux-ppc64le" ]]; then
#   CFLAGS="$(echo $CFLAGS | sed 's/-fno-plt //g')"
#   CXXFLAGS="$(echo $CXXFLAGS | sed 's/-fno-plt //g')"
# fi

export CC=emcc
export CXX=em++
export AR=emar

export EMCC_FORCE_STDLIBS=1
# set initial memory to 130 Mb
export LDFLAGS="$LDFLAGS -s TOTAL_MEMORY=131072000 -s ERROR_ON_UNDEFINED_SYMBOLS=0"
export CFLAGS="$CFLAGS"

# export LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS -s EMCC_FORCE_STDLIBS=1 -s TOTAL_MEMORY=200000000"
# export CFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS"

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DHAVE_LIBEDIT=OFF \
      -DBUILD_SHARED_LIBS=OFF \
      -DLLVM_HAVE_LIBXAR=OFF \
      -DLLVM_ENABLE_LIBXML2=OFF \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_ZLIB=ON \
      -DLLVM_INCLUDE_BENCHMARKS=OFF \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_INCLUDE_GO_TESTS=OFF \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_UTILS=OFF \
      -DLLVM_INSTALL_UTILS=OFF \
      -DLLVM_UTILS_INSTALL_DIR=libexec/llvm \
      -DLLVM_BUILD_LLVM_DYLIB=OFF \
      -DLLVM_LINK_LLVM_DYLIB=OFF \
      -DLLVM_BUILD_TOOLS=OFF \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
      -DLLVM_TARGETS_TO_BUILD=WebAssembly \
      -DLLVM_TABLEGEN=${BUILD_PREFIX}/bin/llvm-tblgen \
      ${CMAKE_ARGS} \
      -GNinja \
      ../llvm

ninja -j${CPU_COUNT}

# if [[ "${target_platform}" == "linux-64" || "${target_platform}" == "osx-64" ]]; then
#     export TEST_CPU_FLAG="-mcpu=haswell"
# else
#     export TEST_CPU_FLAG=""
# fi

# if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
#   # bin/opt -S -vector-library=SVML $TEST_CPU_FLAG -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?

#   if [[ "$target_platform" == linux* ]]; then
#     ln -s $(which $CC) $BUILD_PREFIX/bin/gcc
#   fi

#   ninja -j${CPU_COUNT} check-llvm

#   cd ../llvm/test
#   ../../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
# fi

# cd build
ninja install

IFS='.' read -ra VER_ARR <<< "$PKG_VERSION"

# if [[ "${PKG_NAME}" == libllvm* ]]; then
#     rm -rf $PREFIX/bin
#     rm -rf $PREFIX/include
#     rm -rf $PREFIX/share
#     rm -rf $PREFIX/libexec
#     mv $PREFIX/lib $PREFIX/lib2
#     mkdir -p $PREFIX/lib
#     mv $PREFIX/lib2/libLLVM-${VER_ARR[0]}${SHLIB_EXT} $PREFIX/lib
#     mv $PREFIX/lib2/lib*.so.${VER_ARR[0]} $PREFIX/lib || true
#     mv $PREFIX/lib2/lib*.${VER_ARR[0]}.dylib $PREFIX/lib || true
#     rm -rf $PREFIX/lib2
# elif [[ "${PKG_NAME}" == "llvm-tools" ]]; then
#     rm -rf $PREFIX/lib
#     rm -rf $PREFIX/include
#     rm $PREFIX/bin/llvm-config
#     rm -rf $PREFIX/libexec
# fi
