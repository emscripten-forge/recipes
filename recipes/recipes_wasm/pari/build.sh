#!/usr/bin/env bash
set -euxo pipefail

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export CXXFLAGS="${CXXFLAGS:-} -std=c++11"

emconfigure ./Configure \
    --host=${HOST} \
    --prefix="${PREFIX}" \
    --with-gmp="${PREFIX}" \
    --with-readline-lib="${PREFIX}/lib/libreadline.a" \
    --with-readline-include="${PREFIX}/include/readline" \
    --with-ncurses-lib="${PREFIX}/lib/libncurses.a" \
    --static \
    --graphic=none

cd O*-*

# The generated Makefile hard-codes RANLIB=ranlib, which can't index wasm objects
emmake make all -j${CPU_COUNT:-4} RANLIB=emranlib
emmake make install RANLIB=emranlib

cp gp-sta.js "${PREFIX}/bin/"
cp gp-sta.wasm "${PREFIX}/bin/"
