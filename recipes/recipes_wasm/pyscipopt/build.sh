#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -x

# Build the Cython extension as an Emscripten side module.
FLAGS="-fPIC -sWASM_BIGINT -sSIDE_MODULE=1"
export CFLAGS="${CFLAGS:-} ${FLAGS}"
export CXXFLAGS="${CXXFLAGS:-} ${FLAGS}"

# PySCIPOpt's setup.py only links against `-lscip`, but on Emscripten SCIP and
# its dependencies are static archives. A lazy `-l` placed before the Cython
# objects would not pull anything in, so force-load libscip.a with
# --whole-archive and list its (lazy) transitive dependencies afterwards so
# their referenced members get linked in the right order.
export LDFLAGS="${LDFLAGS:-} -sSIDE_MODULE=1 -sWASM_BIGINT -L${PREFIX}/lib \
  -Wl,--whole-archive ${PREFIX}/lib/libscip.a -Wl,--no-whole-archive \
  ${PREFIX}/lib/libsoplex.a \
  ${PREFIX}/lib/libgmpxx.a \
  ${PREFIX}/lib/libgmp.a \
  ${PREFIX}/lib/libmpfr.a \
  ${PREFIX}/lib/libz.a"

# Tell setup.py where to find SCIP's headers and libraries.
export SCIPOPTDIR="${PREFIX}"

${PYTHON} -m pip install . --no-deps --no-build-isolation -vvv
