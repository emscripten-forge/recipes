#!/bin/bash
set -ex

sed -i 's/Lie\.exe/lie.js/g' Makefile

sed -i 's|^\([[:space:]]*\)\./lie\.js|\1node ./lie.js|g' Makefile
sed -i 's|^\([[:space:]]*\)\./infoind|\1node ./infoind|g' Makefile
sed -i 's|^\([[:space:]]*\)\./learnind|\1node ./learnind|g' Makefile

sed -i '/Printf("%s",prompt_string);/a \    fflush(stdout);' getl.c

make noreadline CC="${CC} -s NODERAWFS=1" CFLAGS="${CFLAGS} -O3"

rm lie.js lie.wasm

WASM_LDFLAGS="-s TOTAL_STACK=32mb -s INITIAL_MEMORY=512mb -s ALLOW_MEMORY_GROWTH=1 -s MAXIMUM_MEMORY=4gb -s FORCE_FILESYSTEM=1"
make noreadline CC="${CC} ${WASM_LDFLAGS}" CFLAGS="${CFLAGS} -O3"

mkdir -p "${PREFIX}/bin"
mkdir -p "${PREFIX}/share/lie"

cp lie.js "${PREFIX}/bin/"
cp lie.wasm "${PREFIX}/bin/"
cp infoind "${PREFIX}/bin/"
cp infoind.wasm "${PREFIX}/bin/"
cp learnind "${PREFIX}/bin/"
cp learnind.wasm "${PREFIX}/bin/"

cp INFO.* LEARN.* "${PREFIX}/share/lie/"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/lie.data" \
  --preload "${PREFIX}/share/lie@/" \
  --js-output="${PREFIX}/bin/lie.data.js"

