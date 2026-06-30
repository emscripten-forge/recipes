#!/usr/bin/env bash
set -Eeuox pipefail

# --- Build-harness contract variables -------------------------------------
: "${RECIPE_DIR:?RECIPE_DIR not set by build harness}"
: "${SRC_DIR:?SRC_DIR not set by build harness}"
: "${PREFIX:?PREFIX not set by build harness}"
: "${BUILD_PREFIX:?BUILD_PREFIX not set by build harness}"
: "${PYTHON:?PYTHON not set by build harness}"
: "${PY_VER:?PY_VER not set by build harness}"

# TODO: Fortran can not hanle LDFLAGS -s flags cause error while compiler detection
# Fortran Compiler Needed meson-build config: https://github.com/scikit-plots/scikit-plots/blob/main/meson.build#L339
# Install custom LLVM and flang which includes patch for common symbols.
# If building locally then you can replace $(pwd) with a fixed location such as $HOME
# to avoid re-downloading on each rebuild.
export LLVM_DIR="$(pwd)/llvm_dir"
LLVM_PKG="llvm_emscripten-wasm32-20.1.7-h2e33cc4_5.tar.bz2"
if [ ! -x "$LLVM_DIR/bin/flang" ]; then
    mkdir -p "$LLVM_DIR"
    wget --quiet "https://github.com/IsabelParedes/llvm-project/releases/download/v20.1.7_emscripten-wasm32/$LLVM_PKG"
    tar -xf "$LLVM_PKG" --directory "$LLVM_DIR"
fi
# Check install
"$LLVM_DIR/bin/flang" --version
"$LLVM_DIR/bin/llvm-nm" --version

# Use local flang-new-wrapper that does some arg mangling.
# Explicitly ensure the wrapper script is executable
cp "$RECIPE_DIR/flang-new-wrapper" "$LLVM_DIR/bin/flang-new-wrapper"
chmod +x "$LLVM_DIR/bin/flang-new-wrapper"
export EM_LLVM_ROOT="$LLVM_DIR"
export FC="$LLVM_DIR/bin/flang-new-wrapper"

# flang-new-wrapper drops ANY argument token starting with "-s" (see
# flang-new-wrapper: `[[ "${arg}" != -s* ]]`). A *two-token* flag like
# "-s SIDE_MODULE=1" only has its "-s" half stripped -- the bare
# "SIDE_MODULE=1" leaks through to flang-new as a stray positional arg.
# Collapsing to a single token "-sSIDE_MODULE=1" makes the whole flag
# disappear as intended.
#
# This pass cleans up whatever LDFLAGS the build harness/activation
# scripts already injected (CFLAGS/CXXFLAGS aren't routed through
# flang-new-wrapper, so they don't need this).
# Remove whitespace after '-s' in LDFLAGS
export LDFLAGS="$(echo "${LDFLAGS:-}" | sed -E 's/-s +/-s/g')"

# new_ldflags=""
# for arg in ${LDFLAGS:-}; do
#     case "$arg" in
#         -s*) ;;
#         *) new_ldflags="$new_ldflags $arg" ;;
#     esac
# done
# export LDFLAGS="${new_ldflags# }"

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
