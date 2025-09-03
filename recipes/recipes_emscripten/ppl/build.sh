#!/bin/bash

set -ex

# PPL uses autotools, so we need to use emconfigure/emmake
echo "Configuring PPL with emscripten"

# Configure with emscripten
emconfigure ./configure \
    --prefix=${PREFIX} \
    --host=wasm32-unknown-emscripten \
    --enable-static \
    --disable-shared \
    --disable-ppl_lcdd \
    --disable-ppl_lpsol \
    --disable-ppl_pips \
    --with-gmp=${PREFIX} \
    --with-glpk=${PREFIX} \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib"

echo "Building PPL"
emmake make -j${CPU_COUNT}

echo "Installing PPL"
emmake make install

echo "PPL build complete"