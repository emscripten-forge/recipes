#!/bin/bash
set -euxo pipefail

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
    -DDISABLE_PYTHON=ON \
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
cp qtui/src/qtloader.js "${PREFIX}/bin/qtloader.js"
cp utils/*.wasm "${PREFIX}/bin/"

# ---------------------------------------------------------------------------
# Preload icons + census databases into the WASM virtual filesystem.
#
# Confirmed from Regina's own source (engine/file/globaldirs.cpp,
# engine/regina-config.h.in): with REGINA_HOME unset and not running from a
# CMake build tree, GlobalDirs falls back to the compile-time REGINA_DATADIR
# default, which is ${CMAKE_INSTALL_FULL_DATADIR}/regina --
# i.e. ${PREFIX}/share/regina, the very same ${PREFIX} this script runs
# under. Icons live at home()+"/icons"; census databases at
# home()+"/data/census". Preloading at the *same* absolute path (rather
# than a shorter virtual one) means Regina's compiled-in fopen() calls
# resolve exactly as they would on a real filesystem, with no extra
# runtime wiring required.
EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/regina-gui.data" \
  --preload "${PREFIX}/share/regina/icons@${PREFIX}/share/regina/icons" \
  --preload "${PREFIX}/share/regina/data/census@${PREFIX}/share/regina/data/census" \
  --js-output="${PREFIX}/bin/regina-gui.data.js"
