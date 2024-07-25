#!/bin/bash

set -ex

export

# Copy flang
# export FLANG_DIR=/home/ihuicatl/Repos/Packaging/llvm-project/_finstall
# cp -r $FLANG_DIR/bin/* $BUILD_PREFIX/bin/
# cp -r $FLANG_DIR/lib/* $BUILD_PREFIX/lib/
# cp -r $FLANG_DIR/include/* $BUILD_PREFIX/include/
# cp -r $FLANG_DIR/share/* $BUILD_PREFIX/share/

export FC=flang-new


export PKG_CONFIG=${BUILD_PREFIX}/bin/pkg-config
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PREFIX/lib

# # Skip non-working checks
export r_cv_header_zlib_h=yes # Otherwise the version check fails
export r_cv_have_bzlib=yes
export ac_cv_lib_lzma_lzma_version_number=yes
export ac_cv_header_lzma_h=yes
export r_cv_have_lzma=yes
export r_cv_have_pcre2utf=yes
export r_cv_have_pcre832=yes
export r_cv_have_curl_https=no
export r_cv_size_max=yes

# export CFLAGS="-O2 --minify=0 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=callMain,FS,ENV,getEnvStrings -sFORCE_FILESYSTEM=1 -sINVOKE_RUN=0 -sMODULARIZE=1 -sSINGLE_FILE=1 -sERROR_ON_UNDEFINED_SYMBOLS=0"


# Get an updated config.sub and config.guess
# cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

chmod +x configure
emconfigure ./configure \
    --prefix=$PREFIX    \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --with-pcre2=no     \
    --with-zlib=no    \
    --with-bzlib=no     \
    --with-lapack=no    \
    --with-blas=no      \
    --with-readline=no  \
    --with-x=no         \
    --with-cairo=no    \
    --enable-static=yes \
    --enable-shared=no  \
    --with-internal-tzcode \
    --with-recommended-packages=no

emmake make -j${CPU_COUNT}
