#!/bin/bash

set -eux

###############################
# CONFIGURE BUILD ENVIRONMENT #
###############################

# Install custom LLVM and flang which includes patch for common symbols
LLVM_DIR="./llvm_dir"
LLVM_PKG="llvm_emscripten-wasm32-20.1.7-h2e33cc4_5.tar.bz2"
mkdir -p $LLVM_DIR
wget --quiet https://github.com/IsabelParedes/llvm-project/releases/download/v20.1.7_emscripten-wasm32/$LLVM_PKG
tar -xf $LLVM_PKG --directory $LLVM_DIR

# Check install
$LLVM_DIR/bin/flang --version
$LLVM_DIR/bin/llvm-nm --version

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

export LDFLAGS="-fPIC -sWASM_BIGINT=1 -Wl,--allow-multiple-definition -L$PREFIX/lib"
export LD_STATIC_FLAG="-static"
export SH_LDFLAGS="-sSIDE_MODULE=1"
export DL_LDFLAGS="-sSIDE_MODULE=1"
export MKOCTFILE_DL_LDFLAGS="-sSIDE_MODULE=1"

export EMCC_CFLAGS="-fPIC -sWASM_BIGINT=1"
export CFLAGS="-O2 -g0 -fPIC -sWASM_BIGINT=1"
export CXXFLAGS="-g0 -fPIC -sWASM_BIGINT=1"

export EXEEXT=".js"
export OCTAVE_CLI_LTLDFLAGS="-sMAIN_MODULE=1 -sALLOW_MEMORY_GROWTH=1 -L$PREFIX/lib -lFortranRuntime -lFortranDecimal -lpcre2-8 -lblas -llapack -lfreetype"

####################
# CONFIGURE OCTAVE #
####################

fail here

# Force disable pthread
sed -i 's/ax_pthread_ok=yes/ax_pthread_ok=no/' configure
export ac_cv_header_pthread_h=no
# Force shared libraries to build as side modules
sed -i 's/SH_LDFLAGS=.*/SH_LDFLAGS=-sSIDE_MODULE=1/' configure
sed -i -E 's/(^|[^a-zA-Z0-9-])-shared($|[^a-zA-Z0-9-])/\1-sSIDE_MODULE=1\2/g' configure
# Shared libraries that are dlopened are built as side modules
sed -i 's/DL_LDFLAGS=.*/DL_LDFLAGS=-sSIDE_MODULE=1/' configure

# We mix F2C calling convention with void return to try to match OpenBlas
sed -i 's/#define F77_RET_T.*/#define F77_RET_T void/' liboctave/util/f77-fcn.h
sed -i 's/#define F77_RETURN.*/#define F77_RETURN(retval) return;/' liboctave/util/f77-fcn.h

# Forcing autotools to NOT rerun after patches
find . -exec touch -t $(date +%Y%m%d%H%M) {} \;

BUILD="x86_64-unknown-linux-gnu"
# Pretend to build for linux because autotools does not know about emscripten
HOST="wasm32-unknown-linux-gnu"

emconfigure ./configure \
   --prefix="${PREFIX}" \
   --build="${BUILD}"\
   --host="${HOST}" \
   --disable-dependency-tracking \
   --enable-fortran-calling-convention="f2c" \
   --enable-shared \
   --disable-64 \
   --disable-dlopen \
   --disable-rpath \
   --disable-openmp \
   --disable-threads \
   --disable-fftw-threads \
   --disable-readline \
   --disable-docs \
   --disable-java \
   --with-blas="-lopenblas" \
   --with-lapack="-lopenblas" \
   --with-pcre2 \
   --with-pcre2-includedir="${PREFIX}/include" \
   --with-pcre2-libdir="${PREFIX}/lib" \
   --without-pcre \
   --without-qt \
   --without-qrupdate \
   --without-framework-carbon

emmake make --jobs 1  # OOM

emmake make install
