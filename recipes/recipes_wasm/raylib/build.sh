#!/bin/bash
set -e

for src in rcore rshapes rtextures rtext rmodels; do
    emcc -c src/${src}.c -Os -Wall -fPIC -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
done
emcc -c src/utils.c  -Os -Wall -fPIC -DPLATFORM_WEB
emcc -c src/raudio.c -Os -Wall -fPIC -DPLATFORM_WEB

emar rcs libraylib.a rcore.o rshapes.o rtextures.o rtext.o rmodels.o utils.o raudio.o

mkdir -p $PREFIX/lib
mkdir -p $PREFIX/include

cp libraylib.a $PREFIX/lib
cp src/*.h $PREFIX/include
