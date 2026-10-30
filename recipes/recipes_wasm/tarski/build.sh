#!/bin/bash
set -ex

sed -i.bak "s/EXTRA_EXPORTED_RUNTIME_METHODS/EXPORTED_RUNTIME_METHODS/g" interpreter/Makefile

sed -i.bak "s|cache/sysroot/include|$PREFIX/include|g" interpreter/Makefile

sed -i.bak "s|/upstream/emscripten/system/lib|$PREFIX/lib|g" interpreter/Makefile

# The interpreter Makefile picks PLATFORM from `uname -s` and only selects
# WASM (TOOLCHAIN=emmake) on non-Darwin hosts; make it independent of the
# build machine so a macOS build takes the same WASM path as Linux.
sed -i.bak "s|^UNAME_S := .*|UNAME_S := Linux|" interpreter/Makefile

# The qepcad/saclib Makefiles call a bare `ranlib`; make sure that is the
# emscripten one so the wasm archives are not rewritten by a native ranlib.
mkdir -p "${SRC_DIR}/_embin"
printf '#!/bin/sh\nexec emranlib "$@"\n' > "${SRC_DIR}/_embin/ranlib"
chmod +x "${SRC_DIR}/_embin/ranlib"
export PATH="${SRC_DIR}/_embin:${PATH}"

yes | TOOLCHAIN=emmake READLINE=0 bash ./build.sh

mkdir -p "$PREFIX/bin"

cp ../tarski.js ../tarski-advanced.js ../tarski-jt-advanced.js "${PREFIX}/bin/"
cp interpreter/src/html/jquery.terminal-white.css interpreter/src/html/tarski-loader.js interpreter/src/html/*.html  "${PREFIX}/bin/"
cp interpreter/src/*.h "${PREFIX}/include/"

cp qesource/source/qepcad qesource/source/qepcad.wasm "${PREFIX}/bin/"
cp qesource/source/qepcad.a "${PREFIX}/lib/"
cp qesource/source/qepcad.h "${PREFIX}/include/"

cp saclib*/include/*.h "${PREFIX}/include/"
cp saclib*/lib/*.a "${PREFIX}/lib/"
