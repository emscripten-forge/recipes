#!/usr/bin/env bash
set -euxo pipefail

# Fix the GFAN include directory path in configure
sed -i.bak 's|GFAN_INC_DIR="$GFAN_LIB_DIR"|GFAN_INC_DIR="$(dirname "$GFAN_LIB_DIR")/include"|g' configure

# libcocoa.a must be built with the emscripten archiver: src/AlgebraicCore's
# Makefile calls a bare `ar`, and a host ar/ranlib (e.g. macOS) breaks the
# wasm archive ("section too large" when linking CoCoAInterpreter)
mkdir -p "${SRC_DIR}/_emar_shim"
printf '#!/bin/sh\nexec emar "$@"\n' > "${SRC_DIR}/_emar_shim/ar"
printf '#!/bin/sh\nexec emranlib "$@"\n' > "${SRC_DIR}/_emar_shim/ranlib"
chmod +x "${SRC_DIR}/_emar_shim/ar" "${SRC_DIR}/_emar_shim/ranlib"
export PATH="${SRC_DIR}/_emar_shim:${PATH}"
export AR=emar
export RANLIB=emranlib

# Boost.System is header-only since 1.69 (no libboost_system on emscripten-forge);
# only Boost.Filesystem is a compiled library
sed -i.bak 's|^SUBLIBS="filesystem  system"|SUBLIBS="filesystem"|' configuration/boost-find-lib.sh

# Fix Normaliz version check
echo '#!/usr/bin/env bash' > configuration/normaliz-version.sh
echo 'echo "30810"' >> configuration/normaliz-version.sh
chmod +x configuration/normaliz-version.sh

# Fix Readline check
# echo '#!/usr/bin/env bash' > configuration/readline-check-cxxflags.sh
# echo 'echo "-L'"${PREFIX}"'/lib -lncurses -ltinfo"' >> configuration/readline-check-cxxflags.sh
chmod +x configuration/readline-check-cxxflags.sh

sed -i.bak 's/ret\[i\]=a.vectormultiply(b.column(i));/assert(false);/g' "${PREFIX}/include/gfanlib_matrix.h"

sed -i.bak 's|GSL_LDLIBS=`pkgconf --libs gsl`|GSL_LDLIBS="-lgsl-symlink -L'"${PREFIX}"'/lib -lgslcblas"|g' configure
# same for the branch taken when pkgconf is not on PATH (GSL brings its own CBLAS,
# there is no liblapack)
sed -i.bak 's|GSL_LDLIBS=-lgsl-symlink  -lgslcblas  -llapack|GSL_LDLIBS=-lgsl-symlink -L'"${PREFIX}"'/lib -lgslcblas|' configure
sed -i.bak 's|NORMALIZ_LDLIBS=-lnormaliz-symlink|NORMALIZ_LDLIBS="-lnormaliz-symlink -L'"${PREFIX}"'/lib -leanticxx -leantic -lnauty -lflint -lmpfr"|g' configure

sed -i.bak 's/( --with-libntl )/( --with-libntl=* )/g' configure
sed -i.bak 's@NTL_LIB="/usr/local/lib/libntl.a".*@NTL_LIB=`echo "$option" | cut -f 2- -d=` ;;@g' configure
sed -i.bak 's/-lntl-symlink  -lpthread/-lntl-symlink/g' configure

export USER_LDFLAGS="-s TOTAL_STACK=32mb -s INITIAL_HEAP=512mb -s ALLOW_MEMORY_GROWTH=1 -s MAXIMUM_MEMORY=4gb -s FORCE_FILESYSTEM=1 -Wl,--allow-multiple-definition -s JSPI=1"

sed -i.bak 's|COCOA5_LDLIBS=-L|COCOA5_LDLIBS='"$USER_LDFLAGS"' -L|g' configure

export CXXFLAGS="-I${PREFIX}/include -DBOOST_ASIO_DISABLE_THREADS -DBOOST_ASIO_DISABLE_SIGNAL_BLOCKER"

emconfigure ./configure \
    --with-cxx=em++ \
    --with-cxxflags="-I${PREFIX}/include -DBOOST_ASIO_DISABLE_THREADS -DBOOST_ASIO_DISABLE_SIGNAL_BLOCKER" \
    --with-libgmp="${PREFIX}/lib/libgmp.a" \
    --with-libcddgmp="${PREFIX}/lib/libcddgmp.a" \
    --with-boost-hdr-dir="${PREFIX}/include" \
    --with-libfrobby="${PREFIX}/lib/libfrobby.a" \
    --with-libgfan="${PREFIX}/lib/libgfan.a" \
    --with-libgsl="${PREFIX}/lib/libgsl.a" \
    --with-libnormaliz="${PREFIX}/lib/libnormaliz.a" \
    --with-libntl="${PREFIX}/lib/libntl.a" \
    --disable-mempool \
    --no-qt-gui \
    --no-readline \
    --prefix="${PREFIX}" 

# Patch LineProviders.C to add `#` before prompt
sed -i.bak '/std::thread/,/detach();/c\
cout << CurrPrompt << flush;
' src/CoCoA-5/LineProviders.C

sed -i.bak 's|\./check-version-defines|true|g' src/CoCoA-5/Makefile

emmake make -j8 library
emmake make -j8 cocoa5 LDFLAGS="$USER_LDFLAGS"
# no `make install`: it only installs libcocoa.a + headers, which the
# cocoalib-static package (pulled in through normaliz-static) already provides

mkdir -p "${PREFIX}/bin/cocoa5"
cp src/CoCoA-5/CoCoAInterpreter "${PREFIX}/bin/cocoa5/CoCoAInterpreter.js"
cp src/CoCoA-5/CoCoAInterpreter.wasm "${PREFIX}/bin/cocoa5/"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/cocoa5/CoCoAInterpreter.data" \
  --preload "${SRC_DIR}/src/CoCoA-5/packages@/src/CoCoA-5/packages" \
  --preload "${SRC_DIR}/src/CoCoA-5/tests@/src/CoCoA-5/tests" \
  --preload "${SRC_DIR}/src/CoCoA-5/CoCoAManual@/src/CoCoA-5/CoCoAManual" \
  --js-output="${PREFIX}/bin/cocoa5/CoCoAInterpreter.data.js"

cp -r "web"/* "${PREFIX}/bin/cocoa5/"
