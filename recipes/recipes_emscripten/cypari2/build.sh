#!/bin/bash

set -euxo pipefail

# ---------------------------------------------------------------------------
# Meson cross file.
#
# meson-python invokes `meson setup` with only a --native-file, so meson
# treats the build as native, sees emcc, and stops with
#
#     ERROR: Emscripten compiler can only be used for cross compilation.
#
# The channel's other meson-python recipes (cysignals, contourpy) each carry
# a copy of this cross file and pass it through -Csetup-args; this is the
# same file and the same handling.
cp "${RECIPE_DIR}/emscripten.meson.cross" "${SRC_DIR}"
sed "s|@(PYTHON)|${PYTHON}|g" "${SRC_DIR}/emscripten.meson.cross" \
    > "${SRC_DIR}/emscripten.meson.new"
mv "${SRC_DIR}/emscripten.meson.new" "${SRC_DIR}/emscripten.meson.cross"
cat "${SRC_DIR}/emscripten.meson.cross"

# ---------------------------------------------------------------------------
# Two things cypari2's meson.build normally discovers by running something
# that a cross build cannot run. patches/0001 lets both come from the
# environment instead, read through the shell rather than through the target
# interpreter.

# 1. The cysignals headers. Upstream locates them with `import cysignals`,
#    but cysignals/__init__.py is `from .signals import ...` followed by
#    init_cysignals(), and `signals` is a compiled extension -- here a wasm
#    one. No interpreter on the build machine can import it, so this is
#    resolved by path rather than by import.
CYSIGNALS_DIR="$(ls -d "${PREFIX}"/lib/python*/site-packages/cysignals 2>/dev/null | head -1)"
if [ -z "${CYSIGNALS_DIR}" ]; then
    echo "ERROR: no cysignals under ${PREFIX}/lib/python*/site-packages;" >&2
    echo "       it is a host dependency of this recipe." >&2
    exit 1
fi
export CYSIGNALS_INCLUDE_DIR="${CYSIGNALS_DIR}"
test -f "${CYSIGNALS_INCLUDE_DIR}/signals.pxd"

# 2. PARI's data directory: the one holding pari.desc, from which autogen
#    generates auto_paridecl.pxd, auto_gen.pxi and auto_instance.pxi. This is
#    what makes the bindings match exactly the PARI being linked.
export PARI_DATADIR="${PREFIX}/share/pari"

# 3. An interpreter that can run that code generation. autogen is pure Python
#    -- it parses pari.desc and writes .pxi/.pxd files -- but the interpreter
#    meson knows about is $PREFIX/bin/python, which this channel's python
#    recipe installs as a shell stub that prints a message and exits 1. Any
#    real interpreter on the build machine will do.
CYPARI2_BUILD_PYTHON=""
for cand in "${BUILD_PREFIX}/venv/cross/bin/python" \
            "${BUILD_PREFIX}/bin/python" \
            "${BUILD_PREFIX}/bin/python3"; do
    if [ -x "${cand}" ] && "${cand}" -c 'import pathlib' >/dev/null 2>&1; then
        CYPARI2_BUILD_PYTHON="${cand}"
        break
    fi
done
if [ -z "${CYPARI2_BUILD_PYTHON}" ]; then
    echo "ERROR: found no runnable python on the build machine for the" >&2
    echo "       autogen step (tried \$BUILD_PREFIX/venv/cross/bin/python," >&2
    echo "       \$BUILD_PREFIX/bin/python and \$BUILD_PREFIX/bin/python3)." >&2
    exit 1
fi
export CYPARI2_BUILD_PYTHON
echo "=== autogen will run under ${CYPARI2_BUILD_PYTHON}"

test -f "${PARI_DATADIR}/pari.desc"
test -f "${PREFIX}/lib/libpari.a"
test -f "${PREFIX}/include/pari/pari.h"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=${SRC_DIR}/emscripten.meson.cross"
