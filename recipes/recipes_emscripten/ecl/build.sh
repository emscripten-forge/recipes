#!/bin/bash
set -e

cd "${SRC_DIR}"

# Stage build a *native* host ECL.
# Explicitly use the build-machine compiler, not emcc,
HOST_ECL_PREFIX="${SRC_DIR}/host-install"

CC="${CC_FOR_BUILD:-gcc}" \
CXX="${CXX_FOR_BUILD:-g++}" \
AR="${AR_FOR_BUILD:-ar}" \
RANLIB="${RANLIB_FOR_BUILD:-ranlib}" \
  ./configure --prefix="${HOST_ECL_PREFIX}"

make -j8
make install

make distclean || true

# strip the x32 ABI suffix that GMP's sub-configure can't handle.
# Use CC_FOR_BUILD here too, not emcc.
BUILD_ARCH="${BUILD:-$(${CC_FOR_BUILD:-gcc} -dumpmachine 2>/dev/null \
  | sed 's/-gnux32$/-gnu/' \
  || echo x86_64-pc-linux-gnu)}"

emconfigure ./configure \
  --host=wasm32-unknown-emscripten \
  --build="${BUILD_ARCH}" \
  --with-cross-config="${SRC_DIR}/src/util/wasm32-unknown-emscripten.cross_config" \
  --prefix="${PREFIX}" \
  --disable-shared \
  --with-tcp=no \
  --with-cmp=no \
  --with-ffi \
  --with-gmp="${PREFIX}" \
  CPPFLAGS="-I${PREFIX}/include" \
  LDFLAGS="-L${PREFIX}/lib"

emmake make -j8 EXEEXT=".html"
emmake make install

mkdir -p "${PREFIX}/bin"
cp build/bin/ecl.js build/bin/ecl.wasm build/bin/ecl.html "${PREFIX}/bin/"
