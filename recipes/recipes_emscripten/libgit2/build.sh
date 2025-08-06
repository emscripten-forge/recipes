# Replace src/libgit2/transports/http.c with emscripten-based implementation.
cp $RECIPE_DIR/http.c src/libgit2/transports/

# Could patch these instead of using sed.
sed -iE 's/\(GIT_CONFIG_FILE_MODE\) 0666/\1 0644/g'     src/libgit2/config.h
sed -iE 's/\(GIT_INDEX_FILE_MODE\) 0666/\1 0644/g'      src/libgit2/index.h
sed -iE 's/\(GIT_OBJECT_DIR_MODE\) 0777/\1 0755/g'      src/libgit2/odb.h
sed -iE 's/\(GIT_OBJECT_FILE_MODE\) 0444/\1 0644/g'     src/libgit2/odb.h
sed -iE 's/\(GIT_PACK_FILE_MODE\) 0444/\1 0644/g'       src/libgit2/pack.h
sed -iE 's/\(GIT_REFLOG_DIR_MODE\) 0777/\1 0755/g'      src/libgit2/reflog.h
sed -iE 's/\(GIT_REFLOG_FILE_MODE\) 0666/\1 0644/g'     src/libgit2/reflog.h
sed -iE 's/\(GIT_REFS_DIR_MODE\) 0777/\1 0755/g'        src/libgit2/refs.h
sed -iE 's/\(GIT_REFS_FILE_MODE\) 0666/\1 0644/g'       src/libgit2/refs.h
sed -iE 's/\(GIT_PACKEDREFS_FILE_MODE\) 0666/\1 0644/g' src/libgit2/refs.h
sed -iE 's/\(GIT_BARE_DIR_MODE\) 0777/\1 0755/g'        src/libgit2/repository.h

mkdir build
cd build

# incompatible-pointer-types warnings do not appear to be a real problem.
export CFLAGS="$CFLAGS     -Wno-incompatible-pointer-types -DNO_MMAP"
export CXXFLAGS="$CXXFLAGS -Wno-incompatible-pointer-types -DNO_MMAP"

emcmake cmake ${CMAKE_ARGS} .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    -DUSE_HTTPS=OFF \
    -DUSE_THREADS=OFF

emmake make install -j$CPU_COUNT

# Install .wasm files as well
cp git2.wasm ${PREFIX}/bin
