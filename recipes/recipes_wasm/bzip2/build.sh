#!/bin/bash
set -ex

emmake make \
    CC="${CC}" \
    AR="${AR}" \
    RANLIB="${RANLIB}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}" \
    PREFIX="${PREFIX}" \
    libbz2.a

mkdir -p "${PREFIX}/lib" "${PREFIX}/include"

cp libbz2.a "${PREFIX}/lib/"
cp bzlib.h "${PREFIX}/include/"