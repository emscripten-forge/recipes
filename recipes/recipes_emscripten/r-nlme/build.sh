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
ln -s $BUILD_PREFIX/bin/clang-18 $BUILD_PREFIX/bin/clang # links to emsdk clang

echo "R_HOME=\$(PREFIX)/lib/R" > $BUILD_PREFIX/lib/R/etc/Makeconf
cat $PREFIX/lib/R/etc/Makeconf >> $BUILD_PREFIX/lib/R/etc/Makeconf

$BUILD_PREFIX/bin/R CMD INSTALL . \
    --no-test-load --no-byte-compile --library=$PREFIX/lib/R/library

rm $PREFIX/lib/R/library/grDevices/libs/cairo.so
rm $PREFIX/lib/R/library/tcltk/libs/tcltk.so