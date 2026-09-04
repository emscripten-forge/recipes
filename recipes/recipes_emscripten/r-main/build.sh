#!/bin/bash

set -eux

export R_HOME="${PREFIX}/lib/R"
export R_SHARE_DIR="${R_HOME}/share"

# Only link libpython (and its transitive deps) for the static-libpython variant.
if [[ "${R_MAIN_MODULE_STATIC_LIBPYTHON}" == "1" ]]; then
    export RPY_LIBS="-lbz2 -lz -lsqlite3 -lffi -lssl -lcrypto -llzma -lpython3.13"
fi

rm $PREFIX/lib/libz.so* || true
rm $PREFIX/lib/libssl.so* || true
rm $PREFIX/lib/libcrypto.so* || true

emmake make install
