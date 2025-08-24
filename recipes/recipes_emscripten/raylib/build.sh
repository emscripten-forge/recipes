
emcc -c src/rcore.c    -Os -Wall -fPIC -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
emcc -c src/rshapes.c  -Os -Wall -fPIC -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
emcc -c src/rtextures.c -Os -Wall -fPIC -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
emcc -c src/rtext.c    -Os -Wall -fPIC -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
emcc -c src/rmodels.c  -Os -Wall -fPIC -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
emcc -c src/utils.c    -Os -Wall -fPIC -DPLATFORM_WEB
emcc -c src/raudio.c   -Os -Wall -fPIC -DPLATFORM_WEB

emar rcs libraylib.a rcore.o rshapes.o rtextures.o rtext.o rmodels.o utils.o raudio.o
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/include

# copy library files
cp libraylib.a $PREFIX/lib
cp src/*.h $PREFIX/include


# compile a test program
emcc -o test.html $RECIPE_DIR/test.cpp -I$PREFIX/include -L$PREFIX/lib -lraylib -sALLOW_MEMORY_GROWTH