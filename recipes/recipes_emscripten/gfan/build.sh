#!/bin/bash
set -euxo pipefail

sed -i \
    -e 's/-march=native//g' \
    -e 's/-finline-limit=1000//g' \
    -e 's/-fno-guess-branch-probability//g' \
    Makefile

sed -i \
    "s|-DGMPRATIONAL|-DGMPRATIONAL -I${PREFIX}/include -I${PREFIX}/include/cddlib|g" \
    Makefile

sed -i \
    "s|-L/usr/local -lcddgmp|-L${PREFIX}/lib -lcddgmp|" \
    Makefile

sed -i \
    -e 's|#include "cdd/setoper\.h"|#include "cddlib/setoper.h"|' \
    -e 's|#include "cdd/cdd_f\.h"|#include "cddlib/cdd_f.h"|' \
    -e 's|#include "cdd/cdd\.h"|#include "cddlib/cdd.h"|' \
    src/lp_cdd.cpp src/gfanlib_zcone.cpp src/app_librarytest.cpp

# emscripten's libc does not provide the non-standard BSD
# u_intNN_t typedefs that src/packedmonomial.h uses -- only the standard
# uintNN_t from <stdint.h> exist there. Normalize to the standard names.
sed -i \
    -e 's/u_int64_t/uint64_t/g' \
    -e 's/u_int16_t/uint16_t/g' \
    src/packedmonomial.h

grep -rlE 'std::execution::(par|par_unseq|seq|unseq)' src/ \
    | xargs -r sed -i -E 's/std::execution::(par|par_unseq|seq|unseq)[[:space:]]*,[[:space:]]*//g'

export LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"

grep -nE 'GMPRATIONAL|march=native|inline-limit|CXXFLAGS' Makefile

emmake make \
    CXX="${CXX}" \
    CC="${CC}" \
    LDFLAGS="${LDFLAGS}" \
    -j"${CPU_COUNT}"

mkdir -p "${PREFIX}/bin"

cp gfan "${PREFIX}/bin/gfan"
cp gfan.wasm "${PREFIX}/bin/gfan.wasm"