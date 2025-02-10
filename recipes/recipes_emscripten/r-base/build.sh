#!/bin/bash

set -e

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
micromamba install -p $BUILD_PREFIX \
    conda-forge/label/llvm_rc::libllvm19=19.1.0.rc2 \
    conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
    -y --no-channel-priority
rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-20 $BUILD_PREFIX/bin/clang # links to emsdk clang

# Skip non-working checks
export r_cv_header_zlib_h=yes
export r_cv_have_bzlib=yes
export r_cv_have_lzma=yes
export r_cv_have_pcre2utf=yes
export r_cv_size_max=yes

# Not supported
export ac_cv_have_decl_getrusage=no
export ac_cv_have_decl_getrlimit=no
export ac_cv_have_decl_sigaltstack=no
export ac_cv_have_decl_wcsftime=no
export ac_cv_have_decl_umask=no
export ac_cv_have_decl_sched_getaffinity=no
export ac_cv_have_decl_sched_setaffinity=no

# SIDE_MODULE + pthread is experimental, and pthread_kill is not implemented
export r_cv_search_pthread_kill=no

# Otherwise set to .not_implemented and cannot be used
export SHLIB_EXT=".so"

export CONFIG_ARGS="--enable-R-static-lib \
--without-readline  \
--without-x \
--with-static-cairo \
--enable-java=no \
--enable-R-profiling=no \
--enable-byte-compiled-packages=no \
--disable-rpath \
--disable-openmp \
--disable-nls \
--with-internal-tzcode \
--with-libdeflate-compression=no \
--with-recommended-packages=no"

#-------------------------------------------------------------------------------
# LINUX BUILD
#-------------------------------------------------------------------------------
# Building R for Linux so that we can use the R and Rscript binaries to build
# the R internal modules for WebAssembly.

mkdir -p _build_linux
pushd _build_linux
(
    export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig
    export PREFIX=$BUILD_PREFIX
    export CC=gcc
    export CXX=g++
    export FC=flang-new
    export CPPFLAGS="-I$BUILD_PREFIX/include"
    export LDFLAGS="-L$BUILD_PREFIX/lib"
    export FC_LEN_T=size_t

    unset CROSS_COMPILING

    ../configure \
        --prefix=$BUILD_PREFIX \
        $CONFIG_ARGS

    make -j${CPU_COUNT}
    # No need to install, we just need the R binary
)
popd

#-------------------------------------------------------------------------------
# WASM BUILD
#-------------------------------------------------------------------------------
# Building R for WebAssembly using the R binary from the Linux build.

# libz.so has an invalid ELF header which causes an error when looking for
# opendir during the configure step. Link with libz.a instead.
rm $PREFIX/lib/libz.so* || true

mkdir -p _build_wasm
pushd _build_wasm
(
    cp $RECIPE_DIR/config.site .

    export CROSS_COMPILING="true"
    export R_EXECUTABLE=$(realpath ..)/_build_linux/bin/exec/R # binary not shell wrapper
    export R_SCRIPT_EXECUTABLE=$(realpath ..)/_build_linux/bin/Rscript
    export LINUX_BUILD_DIR=$(realpath ..)/_build_linux

    # NOTE: the host and build systems are explicitly set to enable the cross-
    # compiling options even though it's not fully supported.
    # Otherwise, it assumes it's not cross-compiling.
    emconfigure ../configure \
        --prefix=$PREFIX    \
        --build="x86_64-conda-linux-gnu" \
        --host="wasm32-unknown-emscripten" \
        $CONFIG_ARGS

    emmake make -j${CPU_COUNT}

    $RECIPE_DIR/cross_libraries.sh --restore $(pwd)

    emmake make install

)
popd
