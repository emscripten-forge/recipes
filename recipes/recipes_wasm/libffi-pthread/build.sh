#!/bin/bash
# libffi for emscripten-wasm32 programs built with pthreads.
#
# Compiled with -pthread (atomics + bulk-memory), like every other object of
# a shared-memory module such as openjdk21's. Its JavaScript calls stackSave,
# which Emscripten 4 only provides in pthread builds, so it is not for
# programs without -pthread (see libffi-jspi). Installed under its own names
# so that it never replaces, or is mistaken for, the libffi package.
set -euxo pipefail

VARIANT="${PKG_NAME}"            # libffi-pthread
STAGE="${SRC_DIR}/_stage"

# WASM_BIGINT must match -sWASM_BIGINT when the program is linked.
emconfigure ./configure \
  --host=wasm32-unknown-linux \
  --prefix="${STAGE}" \
  --enable-static --disable-shared --disable-docs \
  --disable-multi-os-directory --disable-raw-api \
  --disable-dependency-tracking \
  CFLAGS="-O2 -pthread -sUSE_PTHREADS=1 -sSHARED_MEMORY=1 -DWASM_BIGINT"
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
Description: libffi for emscripten-wasm32, built with -pthread
Version: ${PKG_VERSION}
Libs: -L\${libdir} -lffi -pthread
Cflags: -I\${includedir} -pthread
EOF
