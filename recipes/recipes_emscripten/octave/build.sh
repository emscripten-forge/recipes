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


fail here

export FC=flang-new
export F77=flang-new
export F90=flang-new
export F95=flang-new
export F18=flang-new
export FLANG=flang-new

export FFLAGS="--target=wasm32-unknown-emscripten"
export FPICFLAGS="-fPIC"

# rm $BUILD_PREFIX/bin/clang || true
# ln -s $BUILD_PREFIX/bin/clang-20 $BUILD_PREFIX/bin/clang # links to emsdk clang


# flang-new does not support emscripten flags.
#
# Future solution when flang is more mature:
# export FFLAGS="${FFLAGS} -Wno-error=unused-command-line-argument -Qunused-arguments"
#

# Current wrapper to remove all -s CLI otions passed to flang-new
(
   echo '#!/usr/bin/env bash'
   echo 'args=()'
   echo 'for arg in "$@"; do'
   echo '  if [[ "${arg}" != -s* ]]; then'
   echo '    args+=("${arg}")'
   echo '  fi'
   echo 'done'
   echo 'exec' "\"${F77}\"" '"${args[@]}"'
) > flang-new-wrap
chmod +x flang-new-wrap
export F77="${PWD}/flang-new-wrap"
export EM_LLVM_ROOT=$LOLOLOL

# Remove spaces in `-s OPTION` from emscripten to avoid confusion in flang
export LDFLAGS="$(echo "${LDFLAGS}" |  sed -E 's/-s +/-s/g')"

export FLIBS="-lFortranRuntime"
export FFLAGS="${FFLAGS} --target=wasm32-unknown-emscripten"
export CFLAGS="${CFLAGS} --target=wasm32-unknown-emscripten"
export CXXFLAGS="${CXXFLAGS} --target=wasm32-unknown-emscripten"

# Octave overrides xerbla from Lapack.
# Both Blas and Lapack define xerbla zerbla_array lsame.
export LDFLAGS="${LDFLAGS} -Wl,--allow-multiple-definition"

####################
# CONFIGURE OCTAVE #
####################

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
