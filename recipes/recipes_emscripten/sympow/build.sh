#!/usr/bin/env bash
set -euxo pipefail

# Strip architecture-specific flags that might clash with WebAssembly
export CFLAGS="$(echo "${CFLAGS:-}" | sed -E 's/-march=[^ ]+//g; s/-mtune=[^ ]+//g')"

# Patch the Configure script to evaluate Emscripten's Wasm capabilities via Node.js
sed -i 's|-o config/fpubits|-o config/fpubits.js|g' Configure
sed -i 's|-o config/endiantuple|-o config/endiantuple.js|g' Configure

sed -i 's|config/fpubits >|node config/fpubits.js >|g' Configure
sed -i 's@^[ \t]*config/fpubits@node config/fpubits.js@g' Configure
sed -i 's|\$(config/endiantuple)|\$(node config/endiantuple.js)|g' Configure

PREFIX="${PREFIX}" VARPREFIX="${PREFIX}/var" ADDBINPATH=yes sh Configure

# Patch the generated Makefile for cross-compilation
sed -i 's/\$(HELP2MAN) \$(H2MFLAGS) .*/touch \$@/g' Makefile
sed -i 's/\$(SH) armd.sh/echo "Skipping armd.sh for cross-compilation"/g' Makefile
sed -i '/logfile/d' Makefile
sed -i 's|datafiles/\*.txt ||g' Makefile

emmake make all CC="emcc"
emmake make install
cp *.wasm $PREFIX/bin