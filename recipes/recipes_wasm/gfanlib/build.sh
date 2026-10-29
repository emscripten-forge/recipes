#!/usr/bin/env bash
set -euxo pipefail

# Satisfy the hardcoded '#include "cdd/... "' by symlinking locally
ln -s "${PREFIX}/include/cddlib" ./cdd

# Clang flags to forgive legacy C++ template and access rules
export CXXFLAGS="${CXXFLAGS:-} -std=c++11 -fdelayed-template-parsing -fPIC"

export CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/cddlib"
export LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"

emconfigure ./configure \
    --build=${BUILD} \
    --host=${HOST} \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"

emmake make -j${CPU_COUNT}
emmake make install MKINSTALLDIRS="mkdir -p"
