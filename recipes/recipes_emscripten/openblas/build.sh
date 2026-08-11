#!/bin/bash

set -ex

export CC=emcc
export FC=flang-new
export CCOMMON_OPT="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -fwasm-exceptions -sSUPPORT_LONGJMP=wasm -Wno-implicit-function-declaration -Wno-macro-redefined"
export FCOMMON_OPT="$FFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS $FCLIBS"

# It was previously necessary to build on a single core otherwise libopenblas.so can contain
# undefined symbols.  Not sure if this is still required, but keeping it in just in case.
export BUILD_CORES=-j1

export USE_THREAD=0

# WASM128_GENERIC enables WASM SIMD128 kernels (SGEMM/DGEMM, DAXPY, SUM, DOT, ROT, TRSM).
# Makefile.wasm adds -msimd128 automatically for this architecture.
emmake make shared \
    $BUILD_CORES \
    HOSTCC=gcc \
    TARGET=WASM128_GENERIC

emmake make install PREFIX=$PREFIX

# OpenBLAS embeds absolute build-prefix paths in openblas.pc. Rewrite it to be
# relocatable so dependents (e.g. NumPy) can find it via pkg-config after the
# package is installed into a different prefix.
mkdir -p "${PREFIX}/lib/pkgconfig"
cat > "${PREFIX}/lib/pkgconfig/openblas.pc" <<EOF
prefix=\${pcfiledir}/../..
libdir=\${prefix}/lib
includedir=\${prefix}/include
openblas_config=USE_THREAD=0 TARGET=WASM128_GENERIC
version=${PKG_VERSION}
Name: openblas
Description: OpenBLAS is an optimized BLAS library based on GotoBLAS2 1.13 BSD version
Version: \${version}
Libs: -L\${libdir} -lopenblas
Cflags: -I\${includedir}
EOF
