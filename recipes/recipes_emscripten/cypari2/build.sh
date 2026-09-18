#!/bin/bash

set -euxo pipefail

# cypari2's meson.build normally discovers PARI's data directory by running a
# probe program against the PARI it links, which a cross build cannot do.
# patches/0001 lets the answer come from the environment instead. This is the
# directory holding pari.desc, from which autogen generates
# auto_paridecl.pxd, auto_gen.pxi and auto_instance.pxi -- so the bindings
# come out matched to exactly this PARI.
export PARI_DATADIR="${PREFIX}/share/pari"

test -f "${PARI_DATADIR}/pari.desc"
test -f "${PREFIX}/lib/libpari.a"
test -f "${PREFIX}/include/pari/pari.h"

${PYTHON} -m pip install . ${PIP_ARGS}
