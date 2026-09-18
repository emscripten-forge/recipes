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

test -f "${PARI_DATADIR}/pari.desc"
test -f "${PREFIX}/lib/libpari.a"
test -f "${PREFIX}/include/pari/pari.h"

# 3. The generated bindings themselves.
#
#    autogen is pure Python -- it parses pari.desc and writes
#    auto_paridecl.pxd, auto_gen.pxi and auto_instance.pxi -- but meson runs
#    it with the interpreter named in the cross file, which need not work on
#    the build machine. Rather than hand meson an interpreter and hope, run
#    it here, where the error is visible if it fails, and let meson copy the
#    result in. Interpreters are tried in turn against the real work, not
#    against a probe, because only that tells us one actually functions.
AUTOGEN_OUT="${SRC_DIR}/_autogen/cypari2"
rm -rf "${SRC_DIR}/_autogen"
mkdir -p "${AUTOGEN_OUT}"

AUTOGEN_PYTHON=""
for cand in "${BUILD_PREFIX}/venv/cross/bin/python" \
            "${BUILD_PREFIX}/bin/python" \
            "${BUILD_PREFIX}/bin/python3" \
            "$(command -v python3 || true)"; do
    [ -n "${cand}" ] && [ -x "${cand}" ] || continue
    echo "=== trying autogen under ${cand}"
    if ( cd "${SRC_DIR}" && "${cand}" -c "
import sys
sys.path.insert(0, '.')
from autogen import rebuild
rebuild(r'${PARI_DATADIR}', force=True, output=r'${AUTOGEN_OUT}')
" > /dev/null ); then
        AUTOGEN_PYTHON="${cand}"
        break
    fi
    echo "=== that interpreter could not run autogen; trying the next" >&2
done

if [ -z "${AUTOGEN_PYTHON}" ]; then
    echo "ERROR: no interpreter on the build machine could run autogen." >&2
    echo "       The tracebacks above say why." >&2
    exit 1
fi

test -f "${AUTOGEN_OUT}/auto_paridecl.pxd"
test -f "${AUTOGEN_OUT}/auto_gen.pxi"
test -f "${AUTOGEN_OUT}/auto_instance.pxi"
wc -l "${AUTOGEN_OUT}"/auto_gen.pxi "${AUTOGEN_OUT}"/auto_instance.pxi

export CYPARI2_AUTOGEN_DIR="${AUTOGEN_OUT}"
echo "=== bindings generated under ${AUTOGEN_PYTHON}"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=${SRC_DIR}/emscripten.meson.cross"
