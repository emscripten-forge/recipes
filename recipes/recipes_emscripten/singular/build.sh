#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \

# The SINGULAR_MODULES is obtained from "configure.ac", with "python", "pyobject" and "systhreads" removed
SINGULAR_MODULES="bigintm syzextra gfanlib customstd staticdemo subsets freealgebra partialgb gitfan interval cohomo loctriv sispasm machinelearning Order singmathic"
MODULES_CSV="${SINGULAR_MODULES// /,}"

emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --enable-p-procs-static
    --enable-gfanlib
    --enable-staticdemo-module
    --enable-bigintm-module
    --enable-Order-module
    --with-gmp="${PREFIX}" \
    --with-ntl="${PREFIX}" \
    --with-flint="${PREFIX}" \
    --with-ccluster="${PREFIX}" \
    --with-mathicgb=yes \
    --with-builtinmodules=$MODULES_CSV
    --prefix="${PREFIX}"

emmake make -j8
emmake make install