#!/bin/bash

set -ex

echo "PYTHON"

rm -r -f branding

# OpenBLAS must be visible to Meson via pkg-config during the cross build.
# Channel packages may still embed the original build-machine placeholder
# paths in openblas.pc; write corrected .pc files into a build-local
# pkgconfig dir (not $PREFIX — that would ship them in the numpy package).
#
# Also install a scipy-openblas.pc alias. NumPy prefers that name and looks
# it up with plain pkg-config (same pattern as SciPy). That bypasses Meson's
# packages['openblas'] factory, whose void dgemm_()/cblas_dgemm() symbol
# probes fail under wasm-ld signature matching against flang-built OpenBLAS.
PKGCONFIG_DIR="${SRC_DIR}/.emscripten-pkgconfig"
mkdir -p "${PKGCONFIG_DIR}"
for pc_name in openblas scipy-openblas; do
  cat > "${PKGCONFIG_DIR}/${pc_name}.pc" <<EOF
prefix=${PREFIX}
libdir=\${prefix}/lib
includedir=\${prefix}/include
openblas_config=USE_THREAD=0 TARGET=RISCV64_GENERIC
version=0.3.31
Name: ${pc_name}
Description: OpenBLAS is an optimized BLAS library based on GotoBLAS2 1.13 BSD version
Version: \${version}
Libs: -L\${libdir} -lopenblas
Cflags: -I\${includedir}
EOF
done

export PKG_CONFIG_PATH="${PKGCONFIG_DIR}${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"

# Fail early if OpenBLAS is not usable from pkg-config.
pkg-config --exists --print-errors openblas
pkg-config --exists --print-errors scipy-openblas
pkg-config --cflags --libs openblas
test -f "${PREFIX}/include/cblas.h"
test -f "${PREFIX}/lib/libopenblas.so"

# Point Meson's host pkg-config search at the build-local .pc files (cross
# builds do not always inherit PKG_CONFIG_PATH the way native builds do).
cp "${RECIPE_DIR}/emscripten.meson.cross" "${SRC_DIR}/emscripten.meson.cross"
cat >> "${SRC_DIR}/emscripten.meson.cross" <<EOF

[built-in options]
pkg_config_path = ['${PKGCONFIG_DIR}']
EOF
export MESON_CROSS_FILE="${SRC_DIR}/emscripten.meson.cross"

export CFLAGS="$CFLAGS -Wno-return-type -Wno-implicit-function-declaration -msimd128 -fwasm-exceptions -s SUPPORT_LONGJMP"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT 	-s WASM_BIGINT -fwasm-exceptions -s SUPPORT_LONGJMP"

cp $RECIPE_DIR/config/config.h.in  numpy/_core/config.h.in

# otherwise "cython" is not properly executable
echo "add shebang to cython file"
sed -i '1i#!/usr/bin/env python' $BUILD_PREFIX/bin/cython

# replace -fexceptions with -fwasm-exceptions in numpy/_core
sed -i 's/-fexceptions/-fwasm-exceptions/g' numpy/_core/meson.build

# -Dblas=openblas makes NumPy try scipy-openblas first (see numpy/meson.build).
# allow-noblas defaults to true; force OpenBLAS to be required.
${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="-Dblas=openblas" \
    -Csetup-args="-Dlapack=openblas" \
    -Csetup-args="-Dallow-noblas=false" \
    -Csetup-args="--cross-file=$MESON_CROSS_FILE"
