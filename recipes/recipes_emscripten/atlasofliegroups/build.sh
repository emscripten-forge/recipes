#!/bin/bash
set -ex

pushd cwebx
make ctanglex cweavex CC=cc CFLAGS="-O2 -std=c89 -Wno-implicit-int -Wno-implicit-function-declaration"
popd

touch cwebx/ctanglex cwebx/cweavex

WASM_LDFLAGS="-s TOTAL_STACK=32mb -s INITIAL_MEMORY=512mb -s ALLOW_MEMORY_GROWTH=1 -s MAXIMUM_MEMORY=4gb -s FORCE_FILESYSTEM=1"

make -j${CPU_COUNT} readline=false \
    CXX="${CXX} -DNREADLINE" \
    CXXFLAVOR="-O3 -DNDEBUG" \
    LDFLAGS="${WASM_LDFLAGS}" \
    messagedir="/share/atlas/messages/"

mv Fokko Fokko.js
mv atlas atlas.js

mkdir -p "${PREFIX}/bin"
mkdir -p "${PREFIX}/share/atlas/messages"
mkdir -p "${PREFIX}/share/atlas/atlas-scripts"

cp Fokko.js Fokko.wasm "${PREFIX}/bin/"
cp atlas.js atlas.wasm "${PREFIX}/bin/"

cp messages/*.help "${PREFIX}/share/atlas/messages/"
cp messages/intro_mess "${PREFIX}/share/atlas/messages/"
cp atlas-scripts/* "${PREFIX}/share/atlas/atlas-scripts/"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/atlas.data" \
  --preload "${PREFIX}/share/atlas@/share/atlas" \
  --js-output="${PREFIX}/bin/atlas.data.js"