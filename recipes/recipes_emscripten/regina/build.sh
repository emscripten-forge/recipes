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
# Python bindings are enabled and statically linked into regina-gui (see
# patches/0007). CMake's FindPython would otherwise happily resolve to the
# *native* python in $BUILD_PREFIX, since the Interpreter component has to
# be runnable on the build machine while Development must come from the
# wasm32 host environment. So we pin the three pieces explicitly: the
# interpreter from $BUILD_PREFIX (build-time scripts only), and the headers
# and static libpython from $PREFIX (what actually gets linked in).
# ---------------------------------------------------------------------------
# CPython's HACL* hash library.
#
# libpython3.14.a contains md5module.o, sha1module.o and sha2module.o, which
# reference _Py_LibHacl_Hacl_Hash_{MD5,SHA1,SHA2}_*. Those live in CPython's
# libHacl_Hash_*.a archives, built under Modules/_hacl.
#
# Prefer whatever the python package actually ships: CPython installs
# embedding artifacts under lib/pythonX.Y/config-X.Y-<platform>/, so search
# $PREFIX recursively rather than just $PREFIX/lib. Only if nothing turns up
# do we compile the same sources ourselves from the matching CPython release
# (the second source entry in recipe.yaml), because there is no
# emscripten-forge package that provides them separately -- they are
# internal CPython build artifacts, not a standalone library.
#
# No stubbing is involved either way: Modules/_hacl/Hacl_Hash_*.h include
# python_hacl_namespaces.h, which #defines each Hacl_* name to its
# _Py_LibHacl_Hacl_* counterpart, so compiling these files unmodified
# produces exactly the symbols libpython expects, with real implementations.
HACL_LIBRARY="$(find "${PREFIX}" -name 'libHacl*.a' 2>/dev/null | sort | tr '\n' ';')"
if [ -n "${HACL_LIBRARY}" ]; then
    echo "=== using HACL archives shipped by the python package: ${HACL_LIBRARY}"
else
    echo "=== python package ships no libHacl*.a; building from CPython source"
    # The Simd128/Simd256 Blake2 variants are deliberately excluded: they
    # need x86 SSE/AVX intrinsics, and CPython itself only builds them when
    # the host CPU supports them. The rest have no SIMD dependencies.
    HACL_SRC="$(find "${SRC_DIR}/cpython" -type d -name _hacl | head -1)"
    mkdir -p hacl-build
    for f in Hacl_Hash_MD5 Hacl_Hash_SHA1 Hacl_Hash_SHA2 Hacl_Hash_SHA3 \
             Hacl_Hash_Blake2b Hacl_Hash_Blake2s Hacl_HMAC Hacl_Streaming_HMAC \
             Lib_Memzero0; do
        emcc -c -O2 \
            -I"${HACL_SRC}" -I"${HACL_SRC}/include" -I"${HACL_SRC}/internal" \
            "${HACL_SRC}/${f}.c" -o "hacl-build/${f}.o"
    done
    emar rcs hacl-build/libHacl.a hacl-build/*.o
    HACL_LIBRARY="${PWD}/hacl-build/libHacl.a"
fi

PY_VER="$(ls -d "${PREFIX}"/include/python3.* | head -1 | sed 's|.*/python||')"

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
    -DPython_EXECUTABLE="${BUILD_PREFIX}/bin/python${PY_VER}" \
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
