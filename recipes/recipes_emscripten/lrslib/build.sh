#!/usr/bin/env bash
set -euxo pipefail

export CFLAGS="${CFLAGS:-} -Wno-implicit-function-declaration -fPIC"

export CC="emcc"
export CXX="em++"
export AR="emar"
export RANLIB="emranlib"

GMP_FLAGS="-DGMP -I${PREFIX}/include -L${PREFIX}/lib -lgmp"

emmake make default \
    CC="${CC}" \
    CXX="${CXX}" \
    GMP="${GMP_FLAGS}" \
    INCLUDEDIR="${PREFIX}/include" \
    LIBDIR="${PREFIX}/lib" \
    PLRSFLAGS=""

emar rcs liblrs.a \
    lrslong1.o \
    lrslib1.o \
    lrslong2.o \
    lrslib2.o \
    lrslibgmp.o \
    lrsgmp.o \
    lrsdriver.o

mkdir -p "${PREFIX}/include/lrslib"
mkdir -p "${PREFIX}/lib"
mkdir -p "${PREFIX}/bin"

cp lrslib.h lrsdriver.h lrsrestart.h "${PREFIX}/include/lrslib/"
cp lrsarith-011/lrsgmp.h lrsarith-011/lrslong.h lrsarith-011/lrsmp.h "${PREFIX}/include/lrslib/" || true

cp liblrs.a "${PREFIX}/lib/"

shopt -s nullglob
for f in lrs lrsgmp redund minrep fel *.wasm *.js; do
    if [ -f "$f" ] || [ -L "$f" ]; then
        cp -a "$f" "${PREFIX}/bin/"
    fi
done
shopt -u nullglob
