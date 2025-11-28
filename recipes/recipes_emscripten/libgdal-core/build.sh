export EMSCRIPTEN_SYSROOT=$(em-config CACHE)/sysroot
export EMSCRIPTEN_INCLUDE=$EMSCRIPTEN_SYSROOT/include
export EMSCRIPTEN_BIN=$EMSCRIPTEN_SYSROOT/bin
export EMSCRIPTEN_LIB=$EMSCRIPTEN_SYSROOT/lib/wasm32-emscripten/pic

export CFLAGS="$CFLAGS -fPIC"
export LDFLAGS="$LDFLAGS  -fPIC"
export CXXFLAGS="$CXXFLAGS -fPIC"


embuilder build zlib --pic
embuilder build libjpeg --pic

# embuilder build libpng-legacysjlj --pic.  # unfamiliar build target: libpng-legacysjlj
#  lets use the normal one we have as proper recipe

embuilder build sqlite3 --pic

WASM_LIBRARY_DIR=$PREFIX/lib
WASM_INCLUDE_DIR=$PREFIX/include


ls -la $PREFIX/lib

mkdir -p build
cd build && emcmake cmake .. \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
-DCMAKE_INSTALL_PREFIX=$PREFIX \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=True \
-DBUILD_APPS=OFF \
-DCMAKE_C_FLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS}  -fPIC -Wno-deprecated-declarations -Wno-single-bit-bitfield-constant-conversion" \
-DCMAKE_CXX_FLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS} -fPIC  -Wno-deprecated-declarations -Wno-single-bit-bitfield-constant-conversion" \
-DCMAKE_SHARED_LINKER_FLAGS="-sSIDE_MODULE=1 -sWASM_BIGINT" \
-DGDAL_USE_EXTERNAL_LIBS=OFF \
-DGDAL_USE_INTERNAL_LIBS=OFF \
\
-DPROJ_INCLUDE_DIR=$PREFIX/include \
-DPROJ_LIBRARY=$PREFIX/lib/libproj.a \
\
-DGDAL_USE_ICONV=ON \
-DIconv_INCLUDE_DIR=$PREFIX/include \
-DIconv_LIBRARY=$PREFIX/lib/libiconv.a \
\
-DGDAL_USE_TIFF=ON \
-DTIFF_INCLUDE_DIR=$PREFIX/include \
-DTIFF_LIBRARY=$PREFIX/lib/libtiff.a \
\
-DGDAL_USE_GEOS=ON \
-DGEOS_INCLUDE_DIR=$PREFIX/include \
-DGEOS_LIBRARY=$PREFIX/lib/libgeos.so \
\
-DGDAL_USE_ZLIB=ON \
-DZLIB_INCLUDE_DIR=$EMSCRIPTEN_INCLUDE \
-DZLIB_LIBRARY=$EMSCRIPTEN_LIB/libz.a \
\
-DGDAL_USE_PNG=ON \
-DPNG_PNG_INCLUDE_DIR=$PREFIX/include \
-DPNG_LIBRARY_RELEASE=$PREFIX/lib/libpng.a \
\
-DGDAL_USE_JPEG=ON \
-DJPEG_INCLUDE_DIR=$EMSCRIPTEN_INCLUDE \
-DJPEG_LIBRARY_RELEASE=$EMSCRIPTEN_LIB/libjpeg.a \
\
-DGDAL_USE_SQLITE3=ON \
-DSQLite3_INCLUDE_DIR=$EMSCRIPTEN_INCLUDE \
-DSQLite3_LIBRARY=$EMSCRIPTEN_LIB/libsqlite3.a \
-DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC=ON \
\
-DGDAL_USE_GEOTIFF_INTERNAL=ON \
-DGDAL_USE_QHULL_INTERNAL=ON \
-DGDAL_USE_LERC_INTERNAL=ON \
-DGDAL_USE_JSONC_INTERNAL=ON \
-DGDAL_USE_PCRE2=OFF \
-DBUILD_TESTING=OFF \
-DBUILD_PYTHON_BINDINGS=OFF \
-DCMAKE_VERBOSE_MAKEFILE=OFF


# Note:
# CMake tries to link the same libraries multiple times at the final link time.
# This is probably because the same libraries are used in multiple submodules.
# This behavior is okay when those libraries are "shared" libraries,
# but we often build static libraries and linking static libraries
# multiple times results in a duplicated symbol error.
# I wasn't able to find a way to prevent CMake from emitting duplicated libraries.
# This is a hack which removes all duplicated appearances of static libs at the final link time.
FILE="$(pwd)/CMakeFiles/GDAL.dir/linkLibs.rsp"

# Read the entire file
content=$(cat "$FILE")

declare -A seen
result=()

for entry in $content; do
# Remove surrounding quotes
path=${entry#\"}
path=${path%\"}

if [[ "$path" == *.a ]]; then
    base=$(basename "$path")

    # Add only if not seen yet
    if [[ -z "${seen[$base]+x}" ]]; then
        seen[$base]=1
        result+=( "\"$path\"" )
    fi
else
    # Keep non-.a files
    result+=( "\"$path\"" )
fi
done

# Overwrite original file
printf "%s " "${result[@]}" > "$FILE"

echo "Deduped static libraries written back to: $FILE"

emmake make -j 8
emmake make install
