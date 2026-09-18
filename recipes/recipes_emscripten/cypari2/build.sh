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
# same file and the same handling. ${PYTHON} is substituted in so meson's
# python module finds the cross interpreter.
cp "${RECIPE_DIR}/emscripten.meson.cross" "${SRC_DIR}"
sed "s|@(PYTHON)|${PYTHON}|g" "${SRC_DIR}/emscripten.meson.cross" \
    > "${SRC_DIR}/emscripten.meson.new"
mv "${SRC_DIR}/emscripten.meson.new" "${SRC_DIR}/emscripten.meson.cross"
cat "${SRC_DIR}/emscripten.meson.cross"

# ---------------------------------------------------------------------------
# PARI's data directory.
#
# cypari2's meson.build normally discovers this by running a probe program
# against the PARI it links, which a cross build cannot do. patches/0001 lets
# the answer come from the environment instead. This is the directory holding
# pari.desc, from which autogen generates auto_paridecl.pxd, auto_gen.pxi and
# auto_instance.pxi -- so the bindings come out matched to exactly this PARI.
export PARI_DATADIR="${PREFIX}/share/pari"

test -f "${PARI_DATADIR}/pari.desc"
test -f "${PREFIX}/lib/libpari.a"
test -f "${PREFIX}/include/pari/pari.h"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=${SRC_DIR}/emscripten.meson.cross"
