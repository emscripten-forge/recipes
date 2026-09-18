#!/bin/bash

set -euxo pipefail

# ---------------------------------------------------------------------------
# Link the channel's PARI and GMP instead of building our own.
#
# cypari's setup.py looks for its PARI and GMP in libcache/<PARIDIR> and
# libcache/<GMPDIR>, where PARIDIR/GMPDIR are pari32/pari64 and gmp32/gmp64
# chosen from the width of the running interpreter. It then does:
#
#     pari_include_dir   = libcache/<PARIDIR>/include
#     pari_static_library = libcache/<PARIDIR>/lib/libpari.a
#     gmp_static_library  = libcache/<GMPDIR>/lib/libgmp.a
#
# and, if either libcache directory is missing, shells out to
# build_pari.sh, which downloads PARI and GMP tarballs over the network.
#
# Populating libcache ourselves satisfies the existence check, so
# build_pari.sh never runs, and points all three paths at $PREFIX with no
# patch to setup.py at all. Both widths are linked because PARIDIR is
# derived from the build interpreter, not the target.
#
# The include directory is $PREFIX/include rather than $PREFIX/include/pari:
# _pari.c does #include "pari/pari.h".
for d in pari32 pari64; do
    mkdir -p "libcache/${d}"
    ln -sfn "${PREFIX}/include" "libcache/${d}/include"
    ln -sfn "${PREFIX}/lib" "libcache/${d}/lib"
done
for d in gmp32 gmp64; do
    mkdir -p "libcache/${d}"
    ln -sfn "${PREFIX}/lib" "libcache/${d}/lib"
done

test -f "${PREFIX}/lib/libpari.a"
test -f "${PREFIX}/lib/libgmp.a"
test -f "${PREFIX}/include/pari/pari.h"

# setup.py's build_ext sets building_sdist when pari_src/ is present, and
# then returns straight after build_ext.run(). That is the path we want:
# the branch it skips regenerates cypari/auto_gen.pxi and auto_instance.pxi
# with cypari's autogen, which needs PARI's pari.desc -- not shipped by
# either the sdist or the channel's pari package. The sdist does ship the
# already-generated cypari/_pari.c, which is what patches/0001 adjusts.
test -d pari_src

${PYTHON} -m pip install . ${PIP_ARGS}
