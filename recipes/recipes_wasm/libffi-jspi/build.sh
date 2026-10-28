#!/bin/bash
# libffi for emscripten-wasm32 whose ffi_call can suspend with JSPI.
#
# Same flags as the libffi package (no -pthread); only the patch differs.
# Installed under its own names so that it never replaces, or is mistaken
# for, the libffi package.
set -euxo pipefail

VARIANT="${PKG_NAME}"            # libffi-jspi
STAGE="${SRC_DIR}/_stage"

# Note: libffi < 3.5.2 only has a wasm32 port (src/wasm32, 32-bit pointers);
# wasm64 support (src/wasm) arrived in libffi 3.5.2.
if [[ "${target_platform}" == "emscripten-wasm32" ]]; then
  FFI_HOST="wasm32-unknown-linux"
elif [[ "${target_platform}" == "emscripten-wasm64" ]]; then
  FFI_HOST="wasm64-unknown-linux"
else
  echo "Unsupported target_platform: ${target_platform}" >&2
  exit 1
fi

emconfigure ./configure \
  --host="${FFI_HOST}" \
  --prefix="${STAGE}" \
  --enable-static --disable-shared --disable-dependency-tracking \
  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-docs \
  CFLAGS="-O3 -fPIC -sWASM_BIGINT -fwasm-exceptions -sSUPPORT_LONGJMP -DWASM_BIGINT" \
  LDFLAGS="-O3 -sWASM_BIGINT -fwasm-exceptions -sSUPPORT_LONGJMP"
emmake make -j"${CPU_COUNT:-2}"
emmake make install

# Only the headers, the archive and a pkg-config file named after the
# package go into the prefix (no lib/libffi.a, include/ffi.h, libffi.pc or
# man pages that could clash with the libffi package).
install -d "${PREFIX}/include/${VARIANT}" "${PREFIX}/lib/${VARIANT}" \
           "${PREFIX}/lib/pkgconfig" "${PREFIX}/share/licenses/${VARIANT}"
install -m 644 "${STAGE}"/include/*.h "${PREFIX}/include/${VARIANT}/"
install -m 644 "${STAGE}/lib/libffi.a" "${PREFIX}/lib/${VARIANT}/libffi.a"
# programs that link the archive in (statically) ship this notice
install -m 644 LICENSE "${PREFIX}/share/licenses/${VARIANT}/LICENSE"

cat > "${PREFIX}/lib/pkgconfig/${VARIANT}.pc" <<EOF
prefix=${PREFIX}
includedir=\${prefix}/include/${VARIANT}
libdir=\${prefix}/lib/${VARIANT}

Name: ${VARIANT}
Description: libffi for emscripten-wasm32, calls can suspend with JSPI
Version: ${PKG_VERSION}
Libs: -L\${libdir} -lffi
Cflags: -I\${includedir}
EOF
