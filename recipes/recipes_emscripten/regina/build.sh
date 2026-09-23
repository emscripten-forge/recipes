#!/bin/bash
set -euxo pipefail

# Avoid environment-injected flags (from this channel's activation scripts)
# silently overriding/conflicting with what we pass explicitly below --
# particularly relevant now that regina-gui links with -sASYNCIFY=1.
unset EXCEPTION_HANDLING_FLAGS
unset EMCC_CFLAGS

mkdir -p build-wasm
cd build-wasm

# Qt6's QtPublicWasmToolchainHelpers.cmake (invoked during QT_ADD_EXECUTABLE's
# deferred wasm finalization) reads $EMSDK/.emscripten to discover LLVM/
# binaryen paths -- this is normally written by emsdk's own install/activate
# scripts, but emscripten-forge's emscripten package doesn't ship it, so it
# has to be synthesised by hand (same workaround the qt6 recipe itself and
# qt-calculator-experimental use). Without this, configure fails trying to
# open "/.emscripten" (EMSDK resolving to empty).
export EMSDK="${BUILD_PREFIX}/opt/emsdk"
export EMSDK_NODE="$(command -v node)"
if [ ! -f "${EMSDK}/.emscripten" ]; then
  cat > "${EMSDK}/.emscripten" <<EOF
LLVM_ROOT = '${EMSDK}/upstream/bin'
BINARYEN_ROOT = '${EMSDK}/upstream'
EMSCRIPTEN_ROOT = 'upstream/emscripten'
NODE_JS = '${EMSDK_NODE}'
COMPILER_ENGINE = NODE_JS
JS_ENGINES = [NODE_JS]
EOF
fi

WASM_CXXFLAGS="-O2 -fwasm-exceptions"
WASM_LDFLAGS="-O2 -fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=67108864 -sINITIAL_MEMORY=268435456 -L${PREFIX}/lib -lembind"

# ---------------------------------------------------------------------------
# Python version discovery.
#
# Python bindings are enabled and statically linked into regina-gui (see
# patches/0007). FindPython's components have to come from two different
# places -- Interpreter must run on the build machine, while Development
# must be the wasm32 build we link against -- so all three are pinned
# explicitly below rather than left to CMake to guess.
#
# PY_VER is the major.minor of the wasm32 python under $PREFIX -- the one we
# actually link against. Everything below keys off it rather than a literal,
# so the recipe follows whatever variant.yaml pins.
PY_VER="$(ls -d "${PREFIX}"/include/python3.* | head -1 | sed 's|.*/python||')"

# The Interpreter component of CMake's FindPython has to be executable on
# the *build* machine, so it comes from $BUILD_PREFIX (see `python` in the
# recipe's build: requirements); the python under $PREFIX is the wasm32
# build and cannot run here. Prefer an exact version match so FindPython's
# consistency check between Interpreter and Development is satisfied, and
# fall back to whatever python3 is present.
if [ -x "${BUILD_PREFIX}/bin/python${PY_VER}" ]; then
    PY_NATIVE="${BUILD_PREFIX}/bin/python${PY_VER}"
elif [ -x "${BUILD_PREFIX}/bin/python3" ]; then
    PY_NATIVE="${BUILD_PREFIX}/bin/python3"
else
    echo "ERROR: no native python found under ${BUILD_PREFIX}/bin." >&2
    echo "       Add 'python' to the recipe's build: requirements." >&2
    exit 1
fi
echo "=== wasm32 python: ${PY_VER}; native interpreter: ${PY_NATIVE}"

# ---------------------------------------------------------------------------
# CPython's HACL* hash primitives.
#
# libpython contains md5module.o, sha1module.o, sha2module.o, sha3module.o
# and blake2module.o, which reference the HACL* implementations as
# _Py_LibHacl_Hacl_Hash_*. A python package that supports being linked
# statically provides them either as objects inside libpython itself or as
# separate libHacl_*.a archives.
#
# Prefer an archive when one is installed -- CPython puts embedding
# artifacts under lib/pythonX.Y/config-X.Y-<platform>/, so search $PREFIX
# recursively rather than just $PREFIX/lib. Linking it is harmless even if
# libpython already carries the objects: static-archive semantics mean the
# linker only extracts members that resolve an undefined symbol.
#
# Otherwise check that libpython carries them, so that a python which has
# neither fails here, with an explanation, instead of at link time as 43
# undefined symbols with no indication of where they should come from.
HACL_LIBRARY="$(find "${PREFIX}" -name 'libHacl*.a' 2>/dev/null | sort | tr '\n' ';')"
if [ -n "${HACL_LIBRARY}" ]; then
    echo "=== HACL*: linking the archives shipped by the python package:"
    echo "    ${HACL_LIBRARY}"
elif emar t "${PREFIX}/lib/libpython${PY_VER}.a" 2>/dev/null \
        | grep -q '^Hacl_'; then
    echo "=== HACL*: libpython${PY_VER}.a carries the objects itself"
else
    echo "ERROR: the python ${PY_VER} package provides no HACL* hash" >&2
    echo "       primitives -- neither libHacl_*.a under \$PREFIX nor the" >&2
    echo "       objects inside libpython${PY_VER}.a. Linking would fail" >&2
    echo "       with undefined _Py_LibHacl_Hacl_Hash_* symbols, which" >&2
    echo "       libpython's own md5module.o / sha1module.o /" >&2
    echo "       sha2module.o / sha3module.o / blake2module.o reference." >&2
    echo "       This is a packaging bug in the python package, not" >&2
    echo "       something this recipe can work around: see the HACL*" >&2
    echo "       section of README.md for the fix." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Stage Regina's example data files for preloading into the wasm virtual
# filesystem. GlobalDirs::examples() resolves to home()+"/examples", i.e.
# ${PREFIX}/share/regina/examples -- this is what the GUI's "Open Example"
# menu reads. Only the .rga data files are staged: the source examples/
# directory also holds CMakeLists.txt and platform subdirectories that
# would just bloat the .data payload.
mkdir -p examples-stage
cp "${SRC_DIR}"/examples/*.rga examples-stage/
cp "${SRC_DIR}"/examples/README.txt examples-stage/ 2>/dev/null || true
EXAMPLES_DIR="${PWD}/examples-stage"

# Diagnostic: list the static archives available to link against. The
# static libpython drags in every builtin extension module, each of which
# may need a third-party archive (see the FOREACH(PYDEP ...) block in
# patches/0007). If the regina-gui link fails on undefined symbols, this
# listing shows exactly what is -- and is not -- available to satisfy them.
echo "=== static libraries under ${PREFIX} ==="
find "${PREFIX}" -name '*.a' 2>/dev/null | sed "s|${PREFIX}/||" | sort || true
echo "=== end library listing ==="

cmake ${CMAKE_ARGS} .. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=BOTH \
    -DZLIB_LIBRARY="${PREFIX}/lib/libz.a" \
    -DZLIB_INCLUDE_DIR="${PREFIX}/include" \
    -DQT_HOST_PATH="${BUILD_PREFIX}" \
    -DREGINA_INSTALL_TYPE=XDG \
    -DREGINA_KVSTORE=tkrzw \
    -DDISABLE_PYTHON=OFF \
    -DPython_EXECUTABLE="${PY_NATIVE}" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DREGINA_HACL_LIBRARY="${HACL_LIBRARY}" \
    -DREGINA_EXAMPLES_DIR="${EXAMPLES_DIR}" \
    -DDISABLE_GUI=OFF \
    -DHIGHDIM=OFF \
    -DBUILD_INFO="emscripten-forge WASM build" \
    -DCMAKE_CXX_FLAGS="${WASM_CXXFLAGS}" \
    -DCMAKE_C_FLAGS="${WASM_CXXFLAGS}" \
    -DCMAKE_EXE_LINKER_FLAGS="${WASM_LDFLAGS}"

ninja -j"${CPU_COUNT:-2}"
ninja install

cp qtui/src/regina-gui.html "${PREFIX}/bin/regina-gui.html"
cp qtui/src/regina-gui.js "${PREFIX}/bin/regina-gui.js"
cp qtui/src/regina-gui.wasm "${PREFIX}/bin/regina-gui.wasm"
cp qtui/src/regina-gui.data "${PREFIX}/bin/regina-gui.data"
cp qtui/src/qtloader.js "${PREFIX}/bin/qtloader.js"

# Qt's generated regina-gui.html shell shows a spinner that references
# qtlogo.svg; without it the page 404s on load. Qt's wasm finalization
# copies qtloader.js into the build tree but not the logo, so take it from
# wherever the Qt6 package installed it.
QTLOGO="$(find "${SRC_DIR}/build-wasm" "${PREFIX}" -name 'qtlogo.svg' 2>/dev/null | head -1)"
if [ -n "${QTLOGO}" ]; then
    cp "${QTLOGO}" "${PREFIX}/bin/qtlogo.svg"
else
    echo "WARNING: qtlogo.svg not found; regina-gui.html will 404 on it"
fi
cp utils/*.wasm "${PREFIX}/bin/"

INSTALL_DIR="${PREFIX}/share/regina-gui"
mkdir -p "${INSTALL_DIR}"
cp "${PREFIX}"/bin/regina-gui.{html,js,wasm,data} \
   "${PREFIX}/bin/qtloader.js" \
   "${INSTALL_DIR}/"
