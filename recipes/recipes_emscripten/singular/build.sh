#!/usr/bin/env bash
set -euxo pipefail

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"

cp -r "${RECIPE_DIR}/wasm_patch.c" "./"
emcc -c wasm_patch.c -o wasm_patch.o

# The SINGULAR_MODULES is obtained from "configure.ac", with "python", "pyobject", "systhreads", "machinelearning", "Order" removed
SINGULAR_MODULES="bigintm syzextra gfanlib customstd staticdemo subsets freealgebra partialgb gitfan interval cohomo loctriv sispasm singmathic"
MODULES_CSV="${SINGULAR_MODULES// /,}"

emconfigure ./configure \
    CPPFLAGS="-I${PWD}" \
    ac_cv_func_qsort_r=no \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --without-pic \
    --without-readline \
    --enable-p-procs-static \
    --disable-p-procs-dynamic \
    --enable-gfanlib \
    --disable-polymake \
    --disable-pthreads \
    --enable-staticdemo-module \
    --enable-bigintm-module \
    --with-gmp="${PREFIX}" \
    GMP_LIBS="-L${PREFIX}/lib -lgmp" \
    --with-mpfr="${PREFIX}" \
    --with-flint="${PREFIX}" \
    --with-cdd="${PREFIX}" \
    --with-ntl="${PREFIX}" \
    --with-normaliz="${PREFIX}" \
    --with-topcom="${PREFIX}" \
    --with-mathicgb="${PREFIX}" \
    MATHICGB_CFLAGS="-I${PREFIX}/include" \
    MATHICGB_LIBS="-L${PREFIX}/lib -lmathicgb -lmathic -lmemtailor" \
    --with-mathicgb=yes \
    --with-builtinmodules=$MODULES_CSV \
    PTHREAD_CFLAGS="" \
    PTHREAD_LIBS="" \
    CXX="em++" \
    CC="emcc" \
    CXXFLAGS="-D_GNU_SOURCE -std=c++14 -I${PREFIX}/include -I${PREFIX}/include/flint -I${PREFIX}/include/cddlib -I${PWD}" \
    CFLAGS="-D_GNU_SOURCE -I${PREFIX}/include -I${PREFIX}/include/flint -I${PREFIX}/include/cddlib -I${PWD}" \
    LDFLAGS="-L${PREFIX}/lib -s TOTAL_STACK=32mb -s INITIAL_MEMORY=512mb -s ALLOW_MEMORY_GROWTH=1 -s MAXIMUM_MEMORY=4gb -s FORCE_FILESYSTEM=1 -Wl,--allow-multiple-definition -s JSPI=1" \
    --prefix="${PREFIX}"

find . -type f -name "Makefile" -exec sed -i 's/[[:space:]]*-[pP]thread//g' {} +
find . -type f -name "Makefile" -exec sed -i 's/-Wl,-rpath,[^ ]*//g' {} +
find . -type f -name "libtool" -exec sed -i 's/^hardcode_libdir_flag_spec=.*/hardcode_libdir_flag_spec=""/g' {} +
find . -type f -name "libtool" -exec sed -i 's/^runpath_var=.*/runpath_var=""/g' {} +
sed -i 's/systhreads//g' Singular/dyn_modules/Makefile

sed -i 's/Singular_LDADD =/Singular_LDADD = ..\/wasm_patch.o/g' Singular/Makefile

emmake make -j8
emmake make install

cp Singular/all.lib Singular/LIB/

mkdir -p "${PREFIX}/bin/singular"
cp Singular/Singular "${PREFIX}/bin/Singular.js"
cp Singular/Singular.wasm "${PREFIX}/bin/"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/Singular.data" \
  --preload "${SRC_DIR}/Singular/LIB@/LIB" \
  --preload "${SRC_DIR}/doc@/info" \
  --js-output="${PREFIX}/bin/Singular.data.js"

cp -r "web"/* "${PREFIX}/bin/singular/"
cp "${PREFIX}/bin/Singular.js" "${PREFIX}/bin/singular/Singular.js"
cp "${PREFIX}/bin/Singular.wasm" "${PREFIX}/bin/singular/Singular.wasm"
cp "${PREFIX}/bin/Singular.data" "${PREFIX}/bin/singular/Singular.data"
cp "${PREFIX}/bin/Singular.data.js" "${PREFIX}/bin/singular/Singular.data.js"

# Manual for `help` (singular.info, singular.idx), built from doc/ without
# running the examples. libparse runs under node; the trailing "1;" lets perl
# load its output when the last help checksum is 0.
emmake make -C Singular libparse LDFLAGS="-L${PREFIX}/lib -sNODERAWFS=1"
printf '#!/bin/sh\nnode "%s/Singular/libparse" "$@" && echo "1;"\n' "${SRC_DIR}" > Singular/libparse-node
chmod +x Singular/libparse-node
make -C doc -f Makefile-docbuild singular.idx LIBPARSE="${SRC_DIR}/Singular/libparse-node" \
  DOC2TEX_EXAMPLE_EXCLUSIONS=-no_ex TEXI2HTML_OPTS="-init_file t2h_singular.init -short_ext -subdir html"
mkdir -p "${PREFIX}/share/info" "${PREFIX}/share/singular"
cp doc/singular.info "${PREFIX}/share/info/"
cp doc/singular.idx "${PREFIX}/share/singular/"
