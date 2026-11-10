#!/bin/bash

set -eux

################################################################################
# LLVM + FLANG TOOLCHAIN TO SUPPORT COMMON SYMBOLS                             #
################################################################################

export LLVM_DIR="$BUILD_PREFIX/lib/llvm-toolchain"
# export PATH="$LLVM_DIR/bin:$PATH"

# NEEDED:
# wasm-ld: error: liboctave/.libs/liboctave.lax/libranlib.a/advnst.o:
# invalid data segment index: 928
# Remove links to Emscripten's LLVM binaries
rm $BUILD_PREFIX/bin/wasm-ld
ln -s $LLVM_DIR/bin/lld $BUILD_PREFIX/bin/wasm-ld

# NEEDED:
# $BUILD_PREFIX/bin/llvm-ar: error: liboctave/external/ranlib/.libs/libranlib.a:
# 'advnst.o': invalid data segment index: 928
rm $BUILD_PREFIX/bin/llvm-ar
ln -s $LLVM_DIR/bin/llvm-ar $BUILD_PREFIX/bin/llvm-ar

# Intrinsic .mod files (iso_c_binding, etc.) from libflang when installed.
for FINTRINSIC_PATH in "$PREFIX"/lib/clang/*/finclude/flang/"$HOST"; do
  if [ -d "$FINTRINSIC_PATH" ]; then
    export FINTRINSIC_MODS="-fintrinsic-modules-path $FINTRINSIC_PATH"
    break
  fi
done

# Set flags (similar to Flang's activation script)
# export EM_LLVM_ROOT=$LLVM_DIR
export FLANG=$RECIPE_DIR/flang.sh
export FC=$FLANG
export F77=$FLANG
export F90=$FLANG
export F95=$FLANG
export F18=$FLANG
export FFLAGS="-fPIC --target=$HOST ${FINTRINSIC_MODS}"
export FPICFLAGS="-fPIC"
export FCLIBS="-lflang_rt.runtime"

################################################################################
# CONFIGURE BUILD ENVIRONMENT                                                  #
################################################################################

# Copy the patched libtool.m4 before it gets rewritten
rm $BUILD_PREFIX/share/aclocal/libtool.m4
cp m4/libtool.m4 $BUILD_PREFIX/share/aclocal/libtool.m4

autoreconf -fi

# Do not use conda-forge wrapper, it adds paths to system libs
rm $BUILD_PREFIX/bin/pkg-config
mv $BUILD_PREFIX/bin/pkg-config.bin $BUILD_PREFIX/bin/pkg-config

# Copy --pre-js file for octave-cli
envsubst '$PKG_VERSION' < ${RECIPE_DIR}/pre.js > ./pre.js
cli_flags=(
  "--pre-js=$SRC_DIR/pre.js"
  "-sMAIN_MODULE=1"
  "-sNODERAWFS=1"
  "-sALLOW_MEMORY_GROWTH=1"
  "-fwasm-exceptions"
  "-Wl,--allow-multiple-definition"
)
export OCTAVE_CLI_LTLDFLAGS="${cli_flags[*]}"

export CXXFLAGS="-fPIC -fwasm-exceptions -I$PREFIX/include"
export CFLAGS="-fPIC -fwasm-exceptions -I$PREFIX/include"
export CPPFLAGS="-fwasm-exceptions -I$PREFIX/include"
export LDFLAGS="-fPIC -fwasm-exceptions -L$PREFIX/lib"

# For cross tools
export BUILD_CC=gcc
export BUILD_CXX=g++

################################################################################
# CONFIGURE OCTAVE                                                             #
################################################################################

BUILD_DIR="_build"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

export ac_cv_prog_f77_v=-v
export ac_cv_f77_libs="-lflang_rt.runtime"

# Test fails with unknown type name `namespace` - configure bug
export octave_cv_lib_fontconfig=yes

emconfigure \
  env PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
  ../configure \
  --srcdir=".." \
  --prefix="${PREFIX}" \
  --build="${BUILD}" \
  --host="${HOST}" \
  --enable-fortran-calling-convention="gfortran" \
  --disable-lib-visibility-flags \
  --disable-docs \
  --disable-threads \
  --disable-readline \
  --disable-openmp \
  --without-opengl \
  --enable-cross-tools

# NOTE: xeus-octave needs symbols which are incorrectly undeclared in the
# OCTAVE_API, thus --disable-lib-visibility.

################################################################################
# BUILD AND INSTALL                                                            #
################################################################################

emmake make --jobs 3 V=1
emmake make install

# Cross tools
cp src/$HOST-mkoctfile $PREFIX/bin/
cp src/$HOST-octave-config $PREFIX/bin/
