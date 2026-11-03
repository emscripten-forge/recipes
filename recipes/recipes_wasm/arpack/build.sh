#!/bin/bash

set -eux

################################################################################
# Patched LLVM + Flang toolchain
################################################################################

export LLVM_DIR="$BUILD_PREFIX/lib/llvm-toolchain"
export PATH="$LLVM_DIR/bin:$PATH"

# Remove links to Emscripten's LLVM binaries
rm $BUILD_PREFIX/bin/wasm-ld
ln -s $LLVM_DIR/bin/lld $BUILD_PREFIX/bin/wasm-ld

rm $BUILD_PREFIX/bin/llvm-ar
ln -s $LLVM_DIR/bin/llvm-ar $BUILD_PREFIX/bin/llvm-ar

# Intrinsic .mod files (iso_c_binding, etc.) from libflang when installed.
for FINTRINSIC_PATH in "$PREFIX"/lib/clang/*/finclude/flang/"$HOST"; do
  if [ -d "$FINTRINSIC_PATH" ]; then
    export FINTRINSIC_MODS="-fintrinsic-modules-path $FINTRINSIC_PATH"
    break
  fi
done

# Set flags (same as Flang's activation script)
export EM_LLVM_ROOT=$LLVM_DIR
export FLANG=$LLVM_DIR/bin/flang
export FC=$FLANG
export F77=$FLANG
export F90=$FLANG
export F95=$FLANG
export F18=$FLANG
export FFLAGS="--target=$HOST ${FINTRINSIC_MODS}"
export FPICFLAGS="-fPIC"
export FCLIBS="-lflang_rt.runtime"

export CXXFLAGS="-fPIC"
export CFLAGS="-fPIC"
export LDFLAGS="-fPIC -L$PREFIX/lib"

################################################################################

emcmake cmake -S . -B _build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_Fortran_COMPILER=$FC \
    -DCMAKE_Fortran_FLAGS="$FFLAGS" \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DBUILD_SHARED_LIBS=OFF \
    -DMPI=OFF \
    -DICB=ON \
    -DEIGEN=OFF \
    -DPYTHON3=OFF \
    -DEXAMPLES=OFF \
    -DTESTS=OFF

$(which cmake) --build _build -j${CPU_COUNT:-3}
$(which cmake) --install _build
