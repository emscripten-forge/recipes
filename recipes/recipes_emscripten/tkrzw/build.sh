#!/bin/bash

set -euxo pipefail

export CC=emcc
export CXX=em++
export AR=emar
export RANLIB=emranlib

export CFLAGS="${CFLAGS:-} -O2"
export CXXFLAGS="${CXXFLAGS:-} -O2 -std=c++17"

emconfigure ./configure \
    --prefix="${PREFIX}" || cat config.log

emmake make \
    CC="${CC}" \
    CXX="${CXX}" \
    AR="${AR}" \
    RANLIB="${RANLIB}" \
    CFLAGS="${CFLAGS}" \
    CXXFLAGS="${CXXFLAGS}" \
    libtkrzw.a \
    -j"${CPU_COUNT}"

mkdir -p "${PREFIX}/include"
mkdir -p "${PREFIX}/lib/pkgconfig"

cp ./*.h "${PREFIX}/include/"
cp libtkrzw.a "${PREFIX}/lib/"

cat > "${PREFIX}/lib/pkgconfig/tkrzw.pc" <<EOF
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: tkrzw
Description: Tkrzw is a C++ library implementing DBM with various algorithms.
Version: ${PKG_VERSION}
Libs: -L\${libdir} -ltkrzw
Cflags: -I\${includedir}
EOF
