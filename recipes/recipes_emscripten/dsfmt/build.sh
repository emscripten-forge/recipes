#!/bin/bash
set -euxo pipefail

# Same defines Julia uses for its bundled dSFMT (deps/dsfmt.mk), plus
# DSFMT_SHLIB so the header's inline helpers are emitted as real symbols.
# The period is fixed at 2^19937-1; that is what dSFMT.h assumes by default.
DSFMT_DEFS="-DNDEBUG -DDSFMT_MEXP=19937 -DDSFMT_DO_NOT_USE_OLD_NAMES"
DSFMT_OPT="-O3 -finline-functions -fomit-frame-pointer -fno-strict-aliasing -std=c99 -Wall -Wmissing-prototypes"

emcc ${CFLAGS:-} ${DSFMT_DEFS} ${DSFMT_OPT} -DDSFMT_SHLIB -fPIC -c dSFMT.c -o dSFMT.o
emar rcs libdSFMT.a dSFMT.o
emcc ${DSFMT_DEFS} ${DSFMT_OPT} -DDSFMT_SHLIB -fPIC -sSIDE_MODULE=1 -sWASM_BIGINT dSFMT.c -o libdSFMT.so

# Upstream conformance check (what `make std-check` does for MEXP=19937):
# test.c is compiled as a consumer of the header (static inline helpers) and
# linked against the library we just built; its output must match the
# reference file shipped in the tarball.
# (test.c defines DSFMT_DO_NOT_USE_OLD_NAMES itself)
emcc -DNDEBUG -DDSFMT_MEXP=19937 -O2 -std=c99 test.c libdSFMT.a -o test-std-M19937.js
node test-std-M19937.js -v > test-std-M19937.out
diff -q -w test-std-M19937.out dSFMT.19937.out.txt

mkdir -p "${PREFIX}/lib" "${PREFIX}/include"
install -m 644 libdSFMT.a "${PREFIX}/lib/"
install -m 755 libdSFMT.so "${PREFIX}/lib/"
install -m 644 dSFMT.h dSFMT-common.h dSFMT-params*.h "${PREFIX}/include/"
