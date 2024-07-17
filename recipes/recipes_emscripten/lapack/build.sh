#!/bin/bash

set -ex

mkdir -p build
cd build

# Copy flang
export FLANG_DIR=/home/ihuicatl/Repos/Packaging/llvm-project/_finstall
cp -r $FLANG_DIR/bin/* $BUILD_PREFIX/bin/
cp -r $FLANG_DIR/lib/* $BUILD_PREFIX/lib/
cp -r $FLANG_DIR/include/* $BUILD_PREFIX/include/
cp -r $FLANG_DIR/share/* $BUILD_PREFIX/share/


# Build flang runtime
export FLANG_RUNTIME_DIR=/home/ihuicatl/Repos/Packaging/llvm-project/flang/runtime

emcmake cmake -S $FLANG_RUNTIME_DIR -B _fbuild_runtime -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_CXX_COMPILER=clang++

# because alias cmake = emcmake cmake
$(which cmake) --build _fbuild_runtime
$(which cmake) --install _fbuild_runtime

echo "EEEE DONE WITH RUNTIME"
# mkdir -p $PREFIX/include

# export EMSDK_PATH=${EMSCRIPTEN_FORGE_EMSDK_DIR}
# export LDFLAGS="$LDFLAGS -fno-optimize-sibling-calls"
# export FFLAGS="$FFLAGS \
#     --target=wasm32-unknown-emscripten \
#     --generate-object-code \
#     --fixed-form-infer \
#     --implicit-interface"

# CMAKE_INSTALL_LIBDIR="lib" suppresses CentOS default of lib64 (conda expects lib)
export FC=flang-new

LDFLAGS=""

emcmake cmake .. \
    -DCMAKE_Fortran_COMPILER=$FC \
    -DTEST_FORTRAN_COMPILER=OFF \
    -DCBLAS=no \
    -DLAPACKE=no \
    -DBUILD_TESTING=no \
    -DBUILD_DOUBLE=no \
    -DBUILD_COMPLEX=no \
    -DBUILD_COMPLEX16=no \
    -DLAPACKE_WITH_TMG=no \
    -DCMAKE_Fortran_PREPROCESS=yes \
    -DCMAKE_Fortran_FLAGS=$FFLAGS \
    -DCMAKE_INSTALL_LIBDIR="lib" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX

# emcmake cmake \
#   -DCMAKE_INSTALL_PREFIX=${PREFIX} \
#   -DCMAKE_INSTALL_LIBDIR="lib" \
#   -DBUILD_TESTING=ON \
#   -DBUILD_SHARED_LIBS=OFF \
#   -DLAPACKE=ON \
#   -DCBLAS=ON \
#   -DBUILD_DEPRECATED=ON \
#   -DTEST_FORTRAN_COMPILER=OFF \
#   ${CMAKE_ARGS} ..
echo "EEEE"

make install -j${CPU_COUNT} VERBOSE=1
