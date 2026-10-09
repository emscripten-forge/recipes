#!/usr/bin/env bash
set -euxo pipefail

LIBCACHE="${SRC_DIR}/libcache"

# ---------------------------------------------------------------------------
# PARI
#
# cypari normally downloads and builds its own PARI into libcache/.  Build the
# bundled-for-us copy here instead, as a static library only: no gp, no
# graphics, no readline.  It has to be PARI 2.15 rather than the pari package
# (2.17) because PARI 2.16 redefined the `prec` argument of the transcendental
# functions from words to bits and cypari's generated bindings still pass
# words.  GMP comes from the host environment.
# ---------------------------------------------------------------------------
PARI_SRC="${SRC_DIR}/pari-src"
if [ ! -f "${PARI_SRC}/Configure" ]; then
    PARI_SRC="$(echo "${PARI_SRC}"/pari-*)"
fi

pushd "${PARI_SRC}"

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
emconfigure ./Configure \
    --host=wasm32-unknown-emscripten \
    --prefix="${LIBCACHE}/pari" \
    --with-gmp="${PREFIX}" \
    --static \
    --graphic=none \
    --without-readline

pushd Oemscripten-wasm32-unknown
# Build and install the static library first: install-include has no
# prerequisites, so under -j it can run before the generated headers
# (mpinl.h, parimt.h) exist.
emmake make -j"${CPU_COUNT:-2}" install-lib-sta
emmake make install-include install-cfg
# gphelp plus the .tex files it reads; autogen uses it for the docstrings.
make install-doctex
popd

# install-cfg does not reliably place pari.desc, which autogen parses.
mkdir -p "${LIBCACHE}/pari/share/pari"
install -m 644 src/desc/pari.desc "${LIBCACHE}/pari/share/pari/pari.desc"

popd

test -f "${LIBCACHE}/pari/lib/libpari.a"
test -f "${LIBCACHE}/pari/include/pari/pari.h"
test -f "${LIBCACHE}/pari/include/pari/mpinl.h"
test -f "${LIBCACHE}/pari/share/pari/pari.desc"
test -f "${LIBCACHE}/pari/bin/gphelp"

# ---------------------------------------------------------------------------
# cypari
#
# setup.py links against libcache/gmp/lib/libgmp.a; point that at the host
# environment.  Both libraries are static, so cypari has no runtime
# dependency on either.
# ---------------------------------------------------------------------------
ln -s "${PREFIX}" "${LIBCACHE}/gmp"

${PYTHON} -m pip install . ${PIP_ARGS}
