#!/usr/bin/env bash
set -Eeuox pipefail

# --- Build-harness contract variables -------------------------------------
: "${RECIPE_DIR:?RECIPE_DIR not set by build harness}"
: "${SRC_DIR:?SRC_DIR not set by build harness}"
: "${PREFIX:?PREFIX not set by build harness}"
: "${BUILD_PREFIX:?BUILD_PREFIX not set by build harness}"
: "${PYTHON:?PYTHON not set by build harness}"
: "${PY_VER:?PY_VER not set by build harness}"

# replace -fexceptions with -fwasm-exceptions in numpy/_core
# sed -i 's/-fexceptions/-fwasm-exceptions/g' numpy/_core/meson.build
# Write the new flags as single tokens from the start so nothing here
# depends on a later sed pass to be safe for the Fortran link step.
# export CFLAGS="${CFLAGS:-} -sWASM_BIGINT -sSIDE_MODULE=1 -Wno-implicit-function-declaration -fexceptions"
# export CXXFLAGS="${CXXFLAGS:-} -sWASM_BIGINT -sSIDE_MODULE=1 -fexceptions"
# export LDFLAGS="${LDFLAGS} -sWASM_BIGINT -sSIDE_MODULE=1 -fexceptions"

# otherwise "cython" is not properly executable
echo "add shebang to cython file"
sed -i '1i#!/usr/bin/env python' "$BUILD_PREFIX/bin/cython"

# TODO: fix into main repo cause error cython redefinition
sed -i '/^__version__: Final\[str\] = "1\.0\.1"$/d' scikitplot/memmap/_memmap/mem_map.pyx

# Cross file lives in SRC_DIR (writable, per-build copy) -- the upstream
# template intentionally omits a python= entry in [binaries] so we can
# append the build-time interpreter path here. The pip install below
# MUST point at this same SRC_DIR copy, not the RECIPE_DIR original,
# or meson never sees the python= line we just added.
cp "$RECIPE_DIR/emscripten.meson.cross" "$SRC_DIR/emscripten.meson.cross"
echo "python = '${PYTHON}'" >> "$SRC_DIR/emscripten.meson.cross"

# Meson finds numpy_config via pkg_config and numpy.pc
export PKG_CONFIG_PATH="$PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/lib/pkgconfig"

# PIP_ARGS --no-deps
# ${PIP_ARGS:-} is intentionally unquoted: it may hold multiple
# space-separated arguments that pip needs to see as separate words.
# python -m build --sdist -Csetup-args=-Dallow-noblas=true -Csetup-args=-Dcpu-baseline=none -Csetup-args=-Dcpu-dispatch=none
${PYTHON} -m pip install . --no-build-isolation --no-cache-dir -vvv ${PIP_ARGS:-} \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dcpu-baseline=none" \
    -Csetup-args="-Dcpu-dispatch=none" \
    -Ccompile-args="--verbose"
# -Cbuild-dir="_build" \
