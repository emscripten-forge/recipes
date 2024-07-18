#!/bin/bash

set -ex

export

# Copy flang
export FLANG_DIR=/home/ihuicatl/Repos/Packaging/llvm-project/_finstall
cp -r $FLANG_DIR/bin/* $BUILD_PREFIX/bin/
cp -r $FLANG_DIR/lib/* $BUILD_PREFIX/lib/
cp -r $FLANG_DIR/include/* $BUILD_PREFIX/include/
cp -r $FLANG_DIR/share/* $BUILD_PREFIX/share/

export FC=flang-new
# export F77=gfortran
# export F90=gfortran
# export F95=gfortran
# export GFORTRAN=gfortran
# export EMSDK_PATH=${EMSCRIPTEN_FORGE_EMSDK_DIR}
# export FFLAGS="$FFLAGS \
#     --target=wasm32-unknown-emscripten \
#     --generate-object-code \
#     --fixed-form-infer \
#     --implicit-interface"
# export FPICFLAGS="-fPIC"

# export CC=emcc
# export CXX=em++
# export r_cv_header_zlib_h=yes
# export r_cv_have_bzlib=yes


# export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
# export CPPFLAGS=${CPPFLAGS//$PREFIX/$BUILD_PREFIX}
# export NM=$($CC_FOR_BUILD -print-prog-name=nm)
export PKG_CONFIG=${BUILD_PREFIX}/bin/pkg-config
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PREFIX/lib
# export HOST=$BUILD_PREFIX
# export IS_MINIMAL_R_BUILD=1

# TODO: may need to compile twice, 1. regular, 2. cross-compile

# export r_cv_working_mktime=yes

export CC=emcc
export CXX=em++
export CFLAGS="$CFLAGS -I$PREFIX/include"
export CXXFLAGS="$CXXFLAGS -I$PREFIX/include"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"

# Skip non-working checks
export r_cv_header_zlib_h=yes # Otherwise the version check fails
export r_cv_have_bzlib=yes
export ac_cv_lib_lzma_lzma_version_number=yes
export ac_cv_header_lzma_h=yes
export r_cv_have_lzma=yes
export r_cv_have_pcre2utf=yes
export r_cv_have_pcre832=yes
export r_cv_have_curl_https=no
export r_cv_size_max=yes

export ac_cv_func_stpcpy=yes

chmod +x configure
emconfigure ./configure \
    --prefix=$PREFIX    \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --with-pcre2=yes     \
    --with-zlib=$PREFIX/lib/libz.a    \
    --with-bzlib=yes     \
    --with-lapack=no    \
    --with-blas=no      \
    --with-readline=no  \
    --with-x=no         \
    --with-cairo=yes    \
    --enable-static=yes \
    --with-internal-tzcode \
    --with-recommended-packages=no

emmake make -j${CPU_COUNT}
