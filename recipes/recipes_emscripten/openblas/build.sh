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
export TARGET=WASM128_GENERIC

MAKE_ARGS=(
    $BUILD_CORES
    HOSTCC=gcc
    TARGET="${TARGET}"
    USE_THREAD=0
)

emmake make shared "${MAKE_ARGS[@]}"

# ---------------------------------------------------------------------------
# Run OpenBLAS tests under Node.
#
# The Fortran BLAS drivers in test/ and ctest/*.f crash flang 22 when targeting
# wasm32-unknown-emscripten (segfault in ARM64FindSegmentsInFunction). Build the
# library with Fortran as usual, but run tests with NOFORTRAN=1 so ctest uses its
# pure-C drivers (c_*blat*c.c) and the Fortran-only test/ tree is skipped.
#
# Test binaries must be linked as standalone wasm executables (not SIDE_MODULE)
# against the static archive. Patches 0009-0012 adapt the Makefiles/test ABI.
#
# OpenBLAS sets CROSS=1 for emscripten, which skips executing test binaries.
# Override CROSS=0 for the test phase so node actually runs them.
# ---------------------------------------------------------------------------
# Complex L3 f2c drivers allocate large locals; the default 64KB wasm stack is
# too small (stack overflow → OOB). 8MB is enough for c/z blat3.
TEST_LINK_FLAGS="-fwasm-exceptions -sSUPPORT_LONGJMP=wasm -sALLOW_MEMORY_GROWTH=1 -sFORCE_FILESYSTEM=1 -sNODERAWFS=1 -sSTACK_SIZE=8MB"
TEST_CCOMMON_OPT="$EM_FORGE_CFLAGS_BASE ${TEST_LINK_FLAGS} -Wno-implicit-function-declaration -Wno-macro-redefined"
TEST_LDFLAGS="$EM_FORGE_LDFLAGS_BASE $FCLIBS ${TEST_LINK_FLAGS}"
TEST_ARGS=(
    "${MAKE_ARGS[@]}"
    NOFORTRAN=1
    CROSS=0
    EXE=.js
    CCOMMON_OPT="${TEST_CCOMMON_OPT}"
    FCOMMON_OPT="${FFLAGS}"
    LDFLAGS="${TEST_LDFLAGS}"
)

emmake make -C utest all "${TEST_ARGS[@]}"
emmake make -C ctest all1 all2 all3 "${TEST_ARGS[@]}"

emmake make install PREFIX=$PREFIX "${MAKE_ARGS[@]}"

# OpenBLAS embeds absolute build-prefix paths in openblas.pc. Rewrite it to be
# relocatable so dependents (e.g. NumPy) can find it via pkg-config after the
# package is installed into a different prefix.
mkdir -p "${PREFIX}/lib/pkgconfig"
cat > "${PREFIX}/lib/pkgconfig/openblas.pc" <<EOF
prefix=\${pcfiledir}/../..
libdir=\${prefix}/lib
includedir=\${prefix}/include
openblas_config=USE_THREAD=0 TARGET=${TARGET}
version=${PKG_VERSION}
Name: openblas
Description: OpenBLAS is an optimized BLAS library based on GotoBLAS2 1.13 BSD version
Version: \${version}
Libs: -L\${libdir} -lopenblas
Cflags: -I\${includedir}
EOF
