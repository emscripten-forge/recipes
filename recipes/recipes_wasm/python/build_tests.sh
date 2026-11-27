#!/bin/bash
set -e


# Embeds libpython into a MAIN_MODULE executable and runs python_tests.mjs in
# node and in a browser.
# Usage: build_tests.sh core|full
#   core: the env only has python-core. The extension modules of the other
#         outputs (python-ssl, python-sqlite3, ...) must not be importable.
#   full: the env has python (= core + all extension outputs): everything
#         must work, the extension modules are dlopen'ed from lib-dynload.
# The executable is the same in both cases: only the slim core is linked
# (no openssl / sqlite / lzma).
FLAVOR="${1:?usage: build_tests.sh core|full}"
case "$FLAVOR" in
    core) CORE_ONLY=true ;;
    full) CORE_ONLY=false ;;
    *) echo "unknown flavor: $FLAVOR"; exit 1 ;;
esac
echo "==> flavor: $FLAVOR"
echo "export const coreOnly = ${CORE_ONLY};" > test_config.mjs

echo "PY_VER: $PY_VER"

PYTHON_LIB="$PREFIX/lib/libpython${PY_VER}.a"

DYNLOAD_DIR="$PREFIX/lib/python${PY_VER}/lib-dynload"
if [ "$FLAVOR" = "core" ] && ls "$DYNLOAD_DIR"/*.so > /dev/null 2>&1; then
    echo "core flavor, but there are extension modules in $DYNLOAD_DIR"
    exit 1
fi

# everything the slim core needs
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
    "$PREFIX/lib/libffi.a"
    "$PREFIX/lib/libzstd.a"
    "$PYTHON_LIB"
)

# memory limit: emscripten's default is 2GB (also for wasm64)
if emcc -dM -E - < /dev/null | grep -q "__wasm64__"; then
    MAXIMUM_MEMORY=16GB
else
    MAXIMUM_MEMORY=4GB
fi
echo "==> MAXIMUM_MEMORY=$MAXIMUM_MEMORY"

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
    -sMAXIMUM_MEMORY=$MAXIMUM_MEMORY
)


emcc \
    "${FLAGS[@]}" \
    test_main.cpp \
    "${LIBS[@]}" \
    -o test_main.js

echo "==> size of the embed executable (MAIN_MODULE=1, slim core)"
ls -l test_main.wasm
if [ -d "$DYNLOAD_DIR" ]; then
    echo "==> extension modules in lib-dynload"
    ls -l "$DYNLOAD_DIR"
fi

node node_test_wrapper.js

# ---------------------------------------------------------------------------
# browser test (playwright): the same python tests in headless browsers,
# python stdlib preloaded into the emscripten FS. (The exclude patterns match
# the full host path, which may contain e.g. ".../test/..." itself: anchor them
# at lib/pythonX.Y.)
# Browsers: PYTHON_TEST_BROWSERS (default: chromium); skip: PYTHON_SKIP_BROWSER_TEST=1
# ---------------------------------------------------------------------------
if [ "${PYTHON_SKIP_BROWSER_TEST:-0}" = "1" ]; then
    echo "==> skipping browser test (PYTHON_SKIP_BROWSER_TEST=1)"
    exit 0
fi

# --use-preload-plugins: the extension modules (lib-dynload/*.so) are compiled
# asynchronously while the page loads, like the embedders do it (the main
# thread must not compile large wasm modules synchronously in dlopen)
echo "==> compiling and linking (browser)"
emcc \
    "${FLAGS[@]}" \
    -sENVIRONMENT=web,worker \
    --use-preload-plugins \
    --preload-file "$PREFIX/lib/python${PY_VER}@/lib/python${PY_VER}" \
    --exclude-file "*__pycache__*" \
    --exclude-file "*/lib/python${PY_VER}/test/*" \
    --exclude-file "*/lib/python${PY_VER}/idlelib/*" \
    --exclude-file "*/lib/python${PY_VER}/tkinter/*" \
    --exclude-file "*/lib/python${PY_VER}/turtledemo/*" \
    test_main.cpp \
    "${LIBS[@]}" \
    -o test_main_web.js

echo "==> installing browsers: ${PYTHON_TEST_BROWSERS:-chromium}"
python -m playwright install ${PYTHON_TEST_BROWSERS:-chromium}

echo "==> running browser test"
python browser_test.py
