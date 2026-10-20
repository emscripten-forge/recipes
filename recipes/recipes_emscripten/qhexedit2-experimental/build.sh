#!/usr/bin/env bash

# Native Qt6 host tools (moc/rcc/uic/qt-cmake) live under BUILD_PREFIX.
export QT_HOST_PATH="${BUILD_PREFIX}"

# Qt6's QtPublicWasmToolchainHelpers.cmake reads $EMSDK/.emscripten to
# discover LLVM/binaryen paths. emscripten-forge doesn't ship that file,
# so synthesise one (same workaround as the qt6 recipe).
export EMSDK="${EMSCRIPTEN_FORGE_EMSDK_DIR}"
export EMSDK_NODE=$(command -v node)

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

# QHexEdit2 upstream ships a qmake project. Drop our CMakeLists.txt at
# the source root and build from there. Same pattern as qt-calculator.
cp "${RECIPE_DIR}/CMakeLists.txt" "${SRC_DIR}/CMakeLists.txt"

mkdir "${SRC_DIR}/build" && cd "${SRC_DIR}/build"

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DQT_HOST_PATH="${BUILD_PREFIX}" \
    "${SRC_DIR}"

ninja -j "${CPU_COUNT:-2}"

# Install the wasm artifacts into share/qhexedit2-experimental/. Binary
# name is `qhexedit`, which qt-wasm-runner discovers from share/*/*.wasm.
INSTALL_DIR="${PREFIX}/share/qhexedit2-experimental"
mkdir -p "${INSTALL_DIR}"
cp qhexedit.wasm qhexedit.js "${INSTALL_DIR}/"
[ -f qhexedit.html ] && cp qhexedit.html "${INSTALL_DIR}/" || true
[ -f qtloader.js ] && cp qtloader.js "${INSTALL_DIR}/" || true
