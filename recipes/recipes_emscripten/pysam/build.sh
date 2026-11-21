#!/bin/bash

set -eux

# htslib is configured here (not by setup.py) so that its config.h matches emscripten.
# zlib and bzip2 come from the host prefix; lzma and libcurl are disabled as in pyodide-recipes.
# Remove the shared libz/libbz2 so -lz/-lbz2 link statically; otherwise the extensions
# get a DT_NEEDED on libz.so that the browser cannot load.
rm -f "${PREFIX}"/lib/libz.so* "${PREFIX}"/lib/libbz2.so*
export CPPFLAGS="${CPPFLAGS:-} -I${PREFIX}/include"
pushd htslib
emconfigure ./configure \
  --host=wasm32-unknown-emscripten \
  --disable-ref-cache \
  --disable-lzma \
  --disable-libcurl \
  --without-libdeflate \
  CFLAGS="${CFLAGS:-} -fPIC" \
  LDFLAGS="-L${PREFIX}/lib"
popd

export HTSLIB_MODE="separate"
export CFLAGS="${CFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS}"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_SIDE_MODULE_LDFLAGS} -L${PREFIX}/lib"

${PYTHON} -m pip install . --no-deps --no-build-isolation ${PIP_ARGS} -vvv
