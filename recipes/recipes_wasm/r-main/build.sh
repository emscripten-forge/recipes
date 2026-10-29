#!/bin/bash

set -eux

export R_HOME="${PREFIX}/lib/R"
export R_SHARE_DIR="${R_HOME}/share"

# Only link libpython (and its transitive deps) for the static-libpython variant.
if [[ "${R_MAIN_MODULE_STATIC_LIBPYTHON}" == "1" ]]; then
    export PY_STATIC="$PREFIX/lib/python$PY_VER/static"
    if [[ ! -d "$PY_STATIC" ]]; then
        echo "Error: Python static libraries not found at $PY_STATIC" >&2
        exit 1
    fi

    rpy_libs=(
      $PREFIX/lib/libpython${PY_VER}.a
      $PREFIX/lib/libbz2.a
      $PREFIX/lib/libz.a
      $PREFIX/lib/libsqlite3.a
      $PREFIX/lib/libffi.a
      $PREFIX/lib/libzstd.a
      $PREFIX/lib/libssl.a
      $PREFIX/lib/libcrypto.a
      $PREFIX/lib/liblzma.a
      $PY_STATIC/libexpat.a
      $PY_STATIC/libmpdec.a
      $PY_STATIC/libHacl_Hash_BLAKE2.a
      $PY_STATIC/libHacl_Hash_MD5.a
      $PY_STATIC/libHacl_Hash_SHA1.a
      $PY_STATIC/libHacl_Hash_SHA2.a
      $PY_STATIC/libHacl_Hash_SHA3.a
    )
    export RPY_LIBS="${rpy_libs[*]}"
fi

emmake make install
