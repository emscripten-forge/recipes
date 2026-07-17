#!/bin/bash
set -e

cd "${SRC_DIR}"

DATA_DIR="${PREFIX}/share/fricas0-data"
mkdir -p ./fricas0-data
cp -r "${DATA_DIR}"/* ./fricas0-data/


# Stage build a *native* host ECL.
# Explicitly use the build-machine compiler, not emcc,
HOST_ECL_PREFIX="${SRC_DIR}/host-install"

CC="${CC_FOR_BUILD:-gcc} -m32" \
CXX="${CXX_FOR_BUILD:-g++} -m32" \
CFLAGS="${CFLAGS:-} -m32 -O2" \
CXXFLAGS="${CXXFLAGS:-} -m32 -O2" \
LDFLAGS="${LDFLAGS:-} -m32" \
AR="${AR_FOR_BUILD:-ar}" \
RANLIB="${RANLIB_FOR_BUILD:-ranlib}" \
  ./configure --prefix="${HOST_ECL_PREFIX}" \
  --with-gmp=included \
  --disable-shared

make -j8
make install

export ECL_TO_RUN="${HOST_ECL_PREFIX}/bin/ecl"

cd ./fricas0-data

$ECL_TO_RUN -eval '(progn (load "lisp/load-lisp.lisp") (load "lisp/compile-interp.lisp") (quit))'
echo ')lisp (progn (load "lisp/compile-algebra.lisp") (quit))' | $ECL_TO_RUN -load fricas

find interp -maxdepth 1 -type f -name "*.lisp" -delete
find algebra -maxdepth 1 -type f -name "*.lsp" -delete
cd ..

make distclean || true

# strip the x32 ABI suffix that GMP's sub-configure can't handle.
# Use CC_FOR_BUILD here too, not emcc.
BUILD_ARCH="${BUILD:-$(${CC_FOR_BUILD:-gcc} -dumpmachine 2>/dev/null \
  | sed 's/-gnux32$/-gnu/' \
  || echo x86_64-pc-linux-gnu)}"

export USER_LDFLAGS="-sTOTAL_STACK=32mb -s INITIAL_HEAP=512mb -s ALLOW_MEMORY_GROWTH=1 -s MAXIMUM_MEMORY=4gb -s FORCE_FILESYSTEM=1"

emconfigure ./configure \
  --host=wasm32-unknown-emscripten \
  --build="${BUILD_ARCH}" \
  --with-cross-config="${SRC_DIR}/src/util/wasm32-unknown-emscripten.cross_config" \
  --prefix="${PREFIX}" \
  --disable-shared \
  --with-tcp=no \
  --with-cmp=no \
  --with-libffi-prefix="${PREFIX}" \
  --with-libgc-prefix="${PREFIX}" \
  --with-gmp-prefix="${PREFIX}" \
  CPPFLAGS="-I${PREFIX}/include" \
  LDFLAGS="-L${PREFIX}/lib ${USER_LDFLAGS}"

emmake make -j8 EXEEXT=".html"
emmake make install

mkdir -p "${PREFIX}/bin"
cp build/bin/ecl.js build/bin/ecl.wasm build/bin/ecl.html "${PREFIX}/bin/"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/ecl.data" \
  --preload "${SRC_DIR}/fricas0-data@/fricas0-data" \
  --js-output="${PREFIX}/bin/ecl.data.js"

cp -r "web"/* "${PREFIX}/bin/"
