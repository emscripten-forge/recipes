#!/usr/bin/env bash

# Native Qt6 host tools (moc/rcc/uic/lrelease) live under BUILD_PREFIX.
export QT_HOST_PATH="${BUILD_PREFIX}"

# Qt6's QtPublicWasmToolchainHelpers.cmake reads $EMSDK/.emscripten to
# discover LLVM/binaryen paths. emscripten-forge doesn't ship that file,
# so synthesise one — mirrors the workaround in the qt6 recipe.
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

mkdir build && cd build

# DB Browser's CMakeLists uses find_package(SQLite3), which cmake's built-in
# FindSQLite3 resolves via SQLite3_INCLUDE_DIR + SQLite3_LIBRARY. Point them
# at the emscripten-forge sqlite package explicitly since cmake's auto-detect
# won't find the wasm-only library under a cross-root.
cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DQT_HOST_PATH="${BUILD_PREFIX}" \
    -DQT_MAJOR=Qt6 \
    -Dsqlcipher=OFF \
    -DSQLite3_INCLUDE_DIR="${PREFIX}/include" \
    -DSQLite3_LIBRARY="${PREFIX}/lib/libsqlite3.a" \
    -DBUILD_TESTING=OFF \
    "${SRC_DIR}"

ninja -j "${CPU_COUNT:-2}"

# DB Browser produces sqlitebrowser.{wasm,js,html} + qtloader.js in the build
# root when the target is a wasm-emscripten executable. Copy the four wasm
# artifacts into share/sqlitebrowser-experimental/ so the qt-wasm-runner can
# serve them. Artifact filenames stay as sqlitebrowser.* — they come from the
# upstream CMake target name, not the experimental variant label.
INSTALL_DIR="${PREFIX}/share/sqlitebrowser-experimental"
mkdir -p "${INSTALL_DIR}"
cp sqlitebrowser.wasm sqlitebrowser.js qtloader.js "${INSTALL_DIR}/"
# sqlitebrowser.html may or may not be produced depending on Qt version;
# copy it optionally so the recipe doesn't fail if Qt didn't emit one.
[ -f sqlitebrowser.html ] && cp sqlitebrowser.html "${INSTALL_DIR}/" || true
