#!/bin/bash
set -e


echo "PY_VER: $PY_VER"

PYTHON_LIB="$PREFIX/lib/libpython${PY_VER}.a"

OUT="${OUT:-embed.js}"
OBJ="${OUT%.js}.o"




LIBS=(
    "$PREFIX/lib/python${PY_VER}/static/libexpat.a"
    "$PREFIX/lib/python${PY_VER}/static/libmpdec.a"
    "$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_BLAKE2.a"
    "$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_MD5.a"
    "$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_SHA1.a"
    "$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_SHA2.a"
    "$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_SHA3.a"
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
    -sEXPORTED_FUNCTIONS='["_run_python","_uses_wasm_gc_trampoline","_pointer_size"]'
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

# ---------------------------------------------------------------------------
# browser test (playwright): the same python tests in headless browsers,
# python stdlib preloaded into the emscripten FS.
# Browsers: PYTHON_TEST_BROWSERS (default: chromium); skip: PYTHON_SKIP_BROWSER_TEST=1
# ---------------------------------------------------------------------------
if [ "${PYTHON_SKIP_BROWSER_TEST:-0}" = "1" ]; then
    echo "==> skipping browser test (PYTHON_SKIP_BROWSER_TEST=1)"
    exit 0
fi

echo "==> compiling and linking (browser)"
emcc \
    "${FLAGS[@]}" \
    -sENVIRONMENT=web,worker \
    --preload-file "$PREFIX/lib/python${PY_VER}@/lib/python${PY_VER}" \
    --exclude-file "*__pycache__*" \
    --exclude-file "*/test/*" \
    --exclude-file "*/idlelib/*" \
    --exclude-file "*/tkinter/*" \
    --exclude-file "*/turtledemo/*" \
    test_main.cpp \
    "${LIBS[@]}" \
    -o test_main_web.js

echo "==> installing browsers: ${PYTHON_TEST_BROWSERS:-chromium}"
python -m playwright install ${PYTHON_TEST_BROWSERS:-chromium}

echo "==> running browser test"
python browser_test.py
