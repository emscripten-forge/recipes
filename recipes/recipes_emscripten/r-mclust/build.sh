#!/bin/bash

set -eux

# Install custom LLVM and flang which includes patch for common symbols
LLVM_DIR="$(pwd)/llvm_dir"
LLVM_PKG="llvm_emscripten-wasm32-20.1.7-h2e33cc4_5.tar.bz2"
mkdir -p $LLVM_DIR
wget --quiet https://github.com/IsabelParedes/llvm-project/releases/download/v20.1.7_emscripten-wasm32/$LLVM_PKG
tar -xf $LLVM_PKG --directory $LLVM_DIR

# Check install
$LLVM_DIR/bin/flang --version
$LLVM_DIR/bin/llvm-nm --version


# ensure $LLVM_DIR/bin is in PATH
export PATH="$LLVM_DIR/bin:$PATH"

# Set flags
export EM_LLVM_ROOT=$LLVM_DIR
export FLANG=$LLVM_DIR/bin/flang
export FC=$FLANG
export F77=$FLANG
export F90=$FLANG
export F95=$FLANG
export F18=$FLANG

# Set flags
export EM_LLVM_ROOT=$LLVM_DIR
export FLANG=$LLVM_DIR/bin/flang
export FC=$FLANG
export F77=$FLANG
export F90=$FLANG
export F95=$FLANG
export F18=$FLANG

export FFLAGS="-fPIC --target=wasm32-unknown-emscripten"
export FPICFLAGS="-fPIC"
export FLIBS="-lFortranRuntime"
export FCLIBS="-lFortranRuntime"

export LDFLAGS="-fPIC -L$PREFIX/lib -fwasm-exceptions"
export LD_STATIC_FLAG="-static"
export SH_LDFLAGS="-sSIDE_MODULE=1"
export DL_LDFLAGS="-sSIDE_MODULE=1"
export MKOCTFILE_DL_LDFLAGS="-sSIDE_MODULE=1"

export CFLAGS="-O2 -g0 -fPIC -fwasm-exceptions"
export CXXFLAGS="-g0 -fPIC -fwasm-exceptions"

cp $RECIPE_DIR/Makevars $SRC_DIR/src/Makevars

$R CMD INSTALL $R_ARGS .