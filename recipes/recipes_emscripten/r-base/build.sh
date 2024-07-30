#!/bin/bash

echo "HEEELLOO"

# export

# Copy flang
export FLANG_DIR=/home/ihuicatl/Repos/Packaging/llvm-project/_finstall18
cp -r $FLANG_DIR/bin/* $BUILD_PREFIX/bin/
cp -r $FLANG_DIR/lib/* $BUILD_PREFIX/lib/
cp -r $FLANG_DIR/include/* $BUILD_PREFIX/include/
cp -r $FLANG_DIR/share/* $BUILD_PREFIX/share/
unset FLANG_DIR

# Copy Clang RT
cp $RECIPE_DIR/libclang_rt.builtins-wasm32.a $BUILD_PREFIX/lib/
# cp -r $WASI_DIR/bin/* $BUILD_PREFIX/bin/
# cp -r $WASI_DIR/lib/* $BUILD_PREFIX/lib/
# cp -r $WASI_DIR/share/* $BUILD_PREFIX/share/
# unset WASI_DIR

# Copy wabt
# cp /home/ihuicatl/Repos/Emscripten/wabt/build/wasm-objdump $BUILD_PREFIX/bin/
# export objdump=$BUILD_PREFIX/bin/wabm-objdump


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
export r_cv_size_max=yes

export ac_cv_lib_z_inflateInit2_=yes
export ac_cv_lib_bz2_BZ2_bzlibVersion=yes

# export CFLAGS="-O2 --minify=0 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=callMain,FS,ENV,getEnvStrings -sFORCE_FILESYSTEM=1 -sINVOKE_RUN=0 -sMODULARIZE=1 -sSINGLE_FILE=1 -sERROR_ON_UNDEFINED_SYMBOLS=0"

# Libraries to pass to the linker
export LIBS="-lz -lFortranRuntime"

# linker flags, e.g. -L<lib dir> if you have libraries in a
# nonstandard directory <lib dir>
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"

# (Objective) C/C++ preprocessor flags, e.g. -I<include dir> if
# you have headers in a nonstandard directory <include dir>
export CPPFLAGS="-I$PREFIX/include" # Otherwise can't find zlib.h

# Add atomics and bulk-memory features
export CFLAGS="$CFLAGS -matomics -mbulk-memory"
export CXXFLAGS="$CXXFLAGS -matomics -mbulk-memory"

# Otherwise set to .not_implemented and cannot be used
# Must be shared... otherwise duplicate symbol issues
export SHLIB_EXT=".so"

# Get an updated config.sub and config.guess
# cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

export R="${BUILD_PREFIX}/bin/R"
export R_ARGS="--library=${PREFIX}/lib/R/library --no-test-load"

chmod +x ./configure
emconfigure ./configure \
    --prefix=$PREFIX    \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --disable-shared   \
    --enable-blas-shlib=no \
    --enable-R-shlib=no \
    --without-readline  \
    --without-x         \
    --enable-static="[Rblas, Rlapack]" \
    --enable-shared=no  \
    --with-internal-tzcode \
    --with-recommended-packages=no

emmake make -j${CPU_COUNT}