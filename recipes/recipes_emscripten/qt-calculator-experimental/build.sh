#!/usr/bin/env bash

# Native Qt6 host tools (moc/rcc/uic/qmake6) live under BUILD_PREFIX.
export QT_HOST_PATH="${BUILD_PREFIX}"

# Qt6's QtPublicWasmToolchainHelpers.cmake reads $EMSDK/.emscripten to
# discover LLVM/binaryen paths. emscripten-forge doesn't ship that file,
# so synthesise one — mirrors the workaround in the qt6 recipe itself.
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

# Sources come from Qt's own qtbase submodule tarball; only the 5 files
# under examples/widgets/widgets/calculator/ are relevant to this recipe.
# Drop our wasm-friendly CMakeLists.txt in place of Qt's example one and
# build from there. Keeps the recipe free of inlined upstream source.
CALC_DIR="${SRC_DIR}/examples/widgets/widgets/calculator"
cp "${RECIPE_DIR}/CMakeLists.txt" "${CALC_DIR}/CMakeLists.txt"

mkdir "${CALC_DIR}/build" && cd "${CALC_DIR}/build"

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DQT_HOST_PATH="${BUILD_PREFIX}" \
    "${CALC_DIR}"

ninja -j "${CPU_COUNT:-2}"

# Install the four wasm artifacts into a stable share/qt-calculator-experimental/
# path. Artifact filenames are left as qt-calculator.* — they come from the
# CMake target name (which matches the underlying Qt example, not the
# experimental variant label).
INSTALL_DIR="${PREFIX}/share/qt-calculator-experimental"
mkdir -p "${INSTALL_DIR}"
cp qt-calculator.wasm qt-calculator.js qt-calculator.html qtloader.js "${INSTALL_DIR}/"
