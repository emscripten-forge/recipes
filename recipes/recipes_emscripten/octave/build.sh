#!/bin/bash

set -eux

###############################
# CONFIGURE BUILD ENVIRONMENT #
###############################

# set pkg config path to prefix
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
# export MAGICKCORE_HDRI_ENABLE=0
# export MAGICKCORE_QUANTUM_DEPTH=8
# create test program
cat > test.cpp << 'EOF'
#include <Magick++.h>

int main() {
   Magick::ColorRGB c;
   Magick::PixelPacket pix;
}
EOF


emcc test.cpp $(pkg-config --cflags --libs Magick++)



# Install custom LLVM and flang which includes patch for common symbols
LLVM_DIR="$(pwd)/llvm_dir"
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

export LDFLAGS="-fPIC -L$PREFIX/lib -fwasm-exceptions"
export LD_STATIC_FLAG="-static"
export SH_LDFLAGS="-sSIDE_MODULE=1"
export DL_LDFLAGS="-sSIDE_MODULE=1"
export MKOCTFILE_DL_LDFLAGS="-sSIDE_MODULE=1"

export CFLAGS="-O2 -g0 -fPIC -fwasm-exceptions"
export CXXFLAGS="-g0 -fPIC -fwasm-exceptions"

export EXEEXT=".js"
export OCTAVE_CLI_LTLDFLAGS="-sMAIN_MODULE=1 -sALLOW_MEMORY_GROWTH=1 -L$PREFIX/lib -lFortranRuntime -lFortranDecimal -lpcre2-8 -lblas -llapack -lfreetype"

sed -i 's/-fexceptions/-fwasm-exceptions/g' configure

# This flag is set by some of the configure tests which drag in some of the
# compiler libraries including legacy exceptions. They are not needed.
sed -i 's/postdeps_CXX='"'"'.*'"'"'/postdeps_CXX='\'\''/g' configure

####################
# CONFIGURE OCTAVE #
####################

BUILD="x86_64-unknown-linux-gnu"
HOST="wasm32-unknown-emscripten"

BUILD_DIR="_build"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Force autotools to NOT rerun after patches
find . -name "_build*" -prune -o -exec touch -t $(date +%Y%m%d%H%M) {} \;

# Override some tests
export ac_octave_suitesparseconfig_pkg_check=no
export gl_cv_func_setlocale_null_all_mtsafe=no
export gl_cv_func_setlocale_null_one_mtsafe=no
export ac_octave_spqr_check_for_lib=no
export ac_cv_func_pthread_sigmask=no
export ac_cv_header_pthread_h=no
export ac_cv_header_threads_h=no
export ac_cv_type_pthread_t=no
export ac_cv_type_pthread_spinlock_t=no
export gl_cv_const_PTHREAD_CREATE_DETACHED=no
export gl_cv_const_PTHREAD_MUTEX_RECURSIVE=no
export gl_cv_const_PTHREAD_MUTEX_ROBUST=no
export gl_cv_const_PTHREAD_PROCESS_SHARED=no

# Assume putenv is compatible
export gl_cv_func_svid_putenv=yes








# try to find ImageMagick++ with pkg-config
pkg-config --cflags --libs Magick++

# link zlib
export LDFLAGS="$LDFLAGS -lz"

# make sure LDFLAGS contain -lMagick++-6.Q16 -lMagickWand-6.Q16 -lMagickCore-6.Q16
export LDFLAGS="$LDFLAGS -lMagick++-6.Q16 -lMagickWand-6.Q16 -lMagickCore-6.Q16"


# link bz2, libtiff and libpng 
export LDFLAGS="$LDFLAGS -lbz2 -ltiff -lpng"


# jpeg
export LDFLAGS="$LDFLAGS -ljpeg"

# libxml2
export LDFLAGS="$LDFLAGS -lxml2"


# ensure $PREFIX/lib is considered for finding libraries
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"

export LIBS="-lz -lMagick++-6.Q16 -lMagickWand-6.Q16 -lMagickCore-6.Q16 -lbz2 -ltiff -lpng -ljpeg -lxml2"


emconfigure ../configure \
   --prefix="${PREFIX}" \
   --build="${BUILD}"\
   --host="${HOST}" \
   --srcdir=".." \
   --enable-static \
   --enable-fortran-calling-convention="gfortran" \
   --disable-docs \
   --disable-readline \
   --enable-threads=no \
   --disable-threads \
   --disable-fftw-threads \
   --disable-rpath \
   --without-amd \
   --without-camd \
   --without-colamd \
   --without-ccolamd \
   --without-cholmod \
   --without-curl \
   --without-cxsparse \
   --without-suitesparseconfig \
   --without-spqr \
   --without-fftw3 \
   --without-fftw3f \
   --without-glpk \
   --without-glpk \
   --without-hdf5 \
   --without-klu \
   --without-opengl \
   --without-qhull_r \
   --without-qrupdate \
   --without-umfpack \
   --with-z \
   --without-framework-carbon \
   --without-framework-opengl \
   --without-qt \
   --with-magick=Magick++ \
   MAGICK_CFLAGS="$(pkg-config --cflags Magick++)" \
   MAGICK_LIBS="$(pkg-config --libs Magick++)" \
   LIBS="-lz  -lMagick++-6.Q16 -lMagickWand-6.Q16 -lMagickCore-6.Q16 -lbz2 -ltiff -lpng -ljpeg -lxml2" \
|| cat config.log


#####################
# BUILD AND INSTALL #
#####################

emmake make --jobs 3

emmake make install

cp src/octave*.wasm $PREFIX/bin/
