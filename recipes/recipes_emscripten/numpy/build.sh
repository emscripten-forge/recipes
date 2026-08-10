#!/bin/bash

set -ex

echo "PYTHON"

rm -r -f branding

# Prefer the relocatable openblas.pc shipped by the openblas package.
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"

# NumPy tries dependency('scipy-openblas', method: 'pkg-config') before
# dependency('openblas'). That name is not registered in Meson's BLAS
# factory, so it avoids wasm-ld-breaking void dgemm_() symbol probes.
# OpenBLAS only ships openblas.pc; provide a build-local alias derived
# from it (rewrite prefix to $PREFIX — pcfiledir would be wrong here).
PKGCONFIG_DIR="${SRC_DIR}/.emscripten-pkgconfig"
mkdir -p "${PKGCONFIG_DIR}"
sed -e "s|^prefix=.*|prefix=${PREFIX}|" \
    -e 's/^Name: .*/Name: scipy-openblas/' \
    "${PREFIX}/lib/pkgconfig/openblas.pc" \
    > "${PKGCONFIG_DIR}/scipy-openblas.pc"
export PKG_CONFIG_PATH="${PKGCONFIG_DIR}:${PKG_CONFIG_PATH}"

# Fail early if OpenBLAS is not usable from pkg-config.
pkg-config --exists --print-errors openblas
pkg-config --exists --print-errors scipy-openblas
pkg-config --cflags --libs openblas
test -f "${PREFIX}/include/cblas.h"
test -f "${PREFIX}/lib/libopenblas.so"

# Cross builds do not always inherit PKG_CONFIG_PATH; tell Meson where to look.
cp "${RECIPE_DIR}/emscripten.meson.cross" "${SRC_DIR}/emscripten.meson.cross"
cat >> "${SRC_DIR}/emscripten.meson.cross" <<EOF

[built-in options]
pkg_config_path = ['${PKGCONFIG_DIR}', '${PREFIX}/lib/pkgconfig']
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
