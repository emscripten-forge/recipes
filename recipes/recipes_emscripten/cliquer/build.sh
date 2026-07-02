#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \

# Patch the Makefile to respect Emscripten's environment variables
sed -i.bak 's/^CC=gcc/CC?=gcc/' Makefile

# Change '=' to '+=' so Emscripten-forge's standard CFLAGS are appended, not overwritten
sed -i.bak 's/^CFLAGS=/CFLAGS+= /' Makefile

emmake make all -j8
emar rcs libcliquer.a cliquer.o graph.o reorder.o
emcc -shared ${LDFLAGS} -o libcliquer.so cliquer.o graph.o reorder.o

mkdir -p "${PREFIX}/lib"
mkdir -p "${PREFIX}/include/cliquer"
mkdir -p "${PREFIX}/bin"

cp libcliquer.a libcliquer.so "${PREFIX}/lib/"
cp cliquer.h set.h graph.h misc.h reorder.h cliquerconf.h "${PREFIX}/include/cliquer/"
cp cl cl.wasm "${PREFIX}/bin/"