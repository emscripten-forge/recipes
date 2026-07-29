#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \

emconfigure ./Configure \
    --host=wasm32-unknown-emscripten \
    --prefix="${PREFIX}" \
    --with-gmp="${PREFIX}" \
    --with-readline-lib="${PREFIX}/lib/libreadline.a" \
    --with-readline-include="${PREFIX}/include/readline" \
    --with-ncurses-lib="${PREFIX}/lib/libncurses.a" \
    --static \
    --graphic=none

cd Oemscripten-wasm32-unknown

emmake make all -j8
emmake make install

cp gp-sta.js "${PREFIX}/bin/"
cp gp-sta.wasm "${PREFIX}/bin/"