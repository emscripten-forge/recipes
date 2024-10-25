#!/bin/bash

set -e

echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
echo "PKG CONFIG: $(which pkg-config)"
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
echo "PKG_CONFIG_PATH NEW=$PKG_CONFIG_PATH"

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
micromamba install -p $BUILD_PREFIX \
    conda-forge/label/llvm_rc::libllvm19=19.1.0.rc2 \
    conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
    -y --no-channel-priority
rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-18 $BUILD_PREFIX/bin/clang # links to emsdk clang

# Skip non-working checks
export r_cv_header_zlib_h=yes
export r_cv_have_bzlib=yes
export r_cv_have_lzma=yes
export r_cv_have_pcre2utf=yes
export r_cv_size_max=yes
export r_cv_cairo_works=yes

# Not supported
export ac_cv_have_decl_getrusage=no
export ac_cv_have_decl_getrlimit=no
export ac_cv_have_decl_sigaltstack=no
export ac_cv_have_decl_wcsftime=no
export ac_cv_have_decl_umask=no

# SIDE_MODULE + pthread is experimental, and pthread_kill is not implemented
export r_cv_search_pthread_kill=no

export OBJDUMP=llvm-objdump

# Otherwise set to .not_implemented and cannot be used
export SHLIB_EXT=".so"

mkdir _build
cp $RECIPE_DIR/config.site _build/config.site
cd _build

# NOTE: the host and build systems are explicitly set to enable the cross-
# compiling options even though it's not fully supported.
# Otherwise, it assumes it's not cross-compiling.
emconfigure ../configure \
    --prefix=$PREFIX    \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --enable-R-static-lib \
    --with-static-cairo \
    --without-readline  \
    --without-x         \
    --enable-java=no \
    --enable-R-profiling=no \
    --enable-byte-compiled-packages=no \
    --disable-rpath \
    --disable-openmp \
    --disable-nls \
    --with-internal-tzcode \
    --with-recommended-packages=no \
|| cat config.log

# NOTE: Remove the -lFortranRuntime from the FLIBS to avoid double-linking
# when creating the R binary
echo "FLIBS =" >> Makeconf

emmake make -j${CPU_COUNT}
emmake make install

# FIXME: The database files for the internal modules are installed in a "help"
# directory, this copies them to the expected location. It also helps avoid
# packaging r-base files in other R packages when using cross-r-base.
pushd $PREFIX/lib/R/library
    for pkg in $(ls); do
        if [ "$pkg" == "datasets" ]; then
            cp -n ${BUILD_PREFIX}/lib/R/library/$pkg/data/* $pkg/data/
        elif [ -d $pkg/help ]; then
            cp -n $pkg/help/$pkg.rd* $pkg/R/
        fi
    done
popd

# Manually copying .wasm files
cp src/main/R.* $PREFIX/lib/R/bin/exec/
cp src/unix/Rscript.wasm $PREFIX/lib/R/bin/
