# Replace src/libgit2/transports/http.c with emscripten-based implementation.
cp $RECIPE_DIR/http.c src/libgit2/transports/

mkdir build
cd build

export ALLOWED_WARNINGS="-Wno-builtin-macro-redefined -Wno-incompatible-pointer-types-discards-qualifiers -Wno-unused-parameter"

emcmake cmake ${CMAKE_ARGS} .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_C_FLAGS="${EM_FORGE_CFLAGS_BASE} -fPIC -DNO_MMAP ${ALLOWED_WARNINGS}" \
    -DCMAKE_C_STANDARD="99" \
    -DCMAKE_COMPILE_WARNING_AS_ERROR=ON \
    -DBUILD_CLI=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTS=OFF \
    -DUSE_HTTPS=OFF \
    -DUSE_NSEC=OFF \
    -DUSE_THREADS=OFF \
    -DZLIB_INCLUDE_DIR=${PREFIX}/include \
    -DZLIB_LIBRARY=${PREFIX}/lib/libz.a

emmake make install -j$CPU_COUNT
