#!/bin/bash
set -e


echo "PY_VER: $PY_VER"

PYTHON_LIB="$PREFIX/lib/libpython${PY_VER}.a"

OUT="${OUT:-embed.js}"
OBJ="${OUT%.js}.o"




LIBS=(
    "$PREFIX/lib/libexpat.a"
    "$PREFIX/lib/libmpdec.a"
    "$PREFIX/lib/libHacl_Hash_BLAKE2.a"
    "$PREFIX/lib/libHacl_Hash_MD5.a"
    "$PREFIX/lib/libHacl_Hash_SHA1.a"
    "$PREFIX/lib/libHacl_Hash_SHA2.a"
    "$PREFIX/lib/libHacl_Hash_SHA3.a"
    "$PREFIX/lib/libbz2.a"
    "$PREFIX/lib/libz.a"
    "$PREFIX/lib/libsqlite3.a"
    "$PREFIX/lib/libffi.a"
    "$PREFIX/lib/libzstd.a"
    "$PREFIX/lib/libssl.a"
    "$PREFIX/lib/libcrypto.a"
    "$PREFIX/lib/liblzma.a"
    "$PYTHON_LIB"
)

echo "==> compiling and linking"



FLAGS=(
    -O3
    -I"$PREFIX/include"
    -I"$PREFIX/include/python${PY_VER}"
    -sMAIN_MODULE=1
    -O3
    -sERROR_ON_UNDEFINED_SYMBOLS=1
    -sALLOW_MEMORY_GROWTH=1
    -sMODULARIZE=1
    -sEXPORT_NAME="createModule"
    -sEXPORTED_RUNTIME_METHODS='["FS","cwrap", "ccall", "stringToUTF8", "allocateUTF8"]'
    -sEXPORTED_FUNCTIONS='["_run_python"]'
    -sINVOKE_RUN=0
    -sNO_EXIT_RUNTIME=1
    -fwasm-exceptions
    -sSUPPORT_LONGJMP
    -s ALLOW_MEMORY_GROWTH=1
    -s STACK_SIZE=32mb
    -s INITIAL_MEMORY=64MB
)


emcc \
    "${FLAGS[@]}" \
    test_main.cpp \
    "${LIBS[@]}" \
    -o test_main.js


node node_test_wrapper.js