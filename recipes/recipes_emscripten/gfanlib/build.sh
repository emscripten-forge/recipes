#!/usr/bin/env bash
set -euxo pipefail

# Satisfy the hardcoded '#include "cdd/... "' by symlinking locally
ln -s "${PREFIX}/include/cddlib" ./cdd

# Clang flags to forgive legacy C++ template and access rules
export CXXFLAGS="-std=c++11 -fdelayed-template-parsing"

export CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/cddlib"
export LDFLAGS="-L${PREFIX}/lib"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"


emmake make -j8
emmake make install MKINSTALLDIRS="mkdir -p"
