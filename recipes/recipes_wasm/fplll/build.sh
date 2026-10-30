#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

: "${CFLAGS:=}" "${CXXFLAGS:=}" "${LDFLAGS:=}"

# no threads: drop -pthread from the inherited flags
emconfigure ./configure \
    --build=${BUILD} \
    --host=${HOST} \
    --enable-static \
    --disable-shared \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --prefix="${PREFIX}" \
    CFLAGS="${CFLAGS//-pthread/} -fPIC" \
    CXXFLAGS="${CXXFLAGS//-pthread/} -fPIC" \
    LDFLAGS="${LDFLAGS//-pthread/} -L${PREFIX}/lib"

# configure's pthread check adds -pthread / -lpthread to the Makefiles
find . -type f -name Makefile -exec sed -i.bak -e 's/-lpthread//g' -e 's/-pthread//g' {} +

emmake make -j${CPU_COUNT}
emmake make install
