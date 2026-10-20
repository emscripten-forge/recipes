#!/bin/bash
set -ex

sed -i "s/EXTRA_EXPORTED_RUNTIME_METHODS/EXPORTED_RUNTIME_METHODS/g" interpreter/Makefile

sed -i "s|cache/sysroot/include|$PREFIX/include|g" interpreter/Makefile

sed -i "s|/upstream/emscripten/system/lib|$PREFIX/lib|g" interpreter/Makefile

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