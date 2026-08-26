
if [ "$PKG_NAME" = "libzlib" ]; then
  ZLIB_BUILD_SHARED=ON
  ZLIB_BUILD_STATIC=OFF
elif [ "$PKG_NAME" = "libzlib-static" ]; then
  ZLIB_BUILD_SHARED=OFF
  ZLIB_BUILD_STATIC=ON
else
  echo "Unknown package name: $PKG_NAME"
  exit 1
fi


mkdir build
cd build

# Set compiler flags
export CFLAGS="$CFLAGS $EMCC_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EMCC_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# Configure step
emcmake cmake ${CMAKE_ARGS} ..      \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  \
    -DZLIB_BUILD_EXAMPLES=OFF       \
    -DZLIB_BUILD_SHARED=$ZLIB_BUILD_SHARED \
    -DZLIB_BUILD_STATIC=$ZLIB_BUILD_STATIC \
    -DBUILD_SHARED_LIBS=$ZLIB_BUILD_SHARED \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_VERBOSE_MAKEFILE=ON     \
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS" \
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS" \
    -DCMAKE_MODULE_LINKER_FLAGS_RELEASE="$LDFLAGS" \
    # -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake

# Build step
emmake ninja -v

# Install step
ninja install


# this is already fixed upstream but not merged
# https://github.com/madler/zlib/issues/1177
if [ "$PKG_NAME" = "libzlib" ]; then
    PATH_TO_CONFIG="$PREFIX/lib/cmake/zlib/ZLIBConfig.cmake"
    sed -i.bak 's/"shared" "static"/"shared"/' "$PATH_TO_CONFIG"
elif [ "$PKG_NAME" = "libzlib-static" ]; then
    PATH_TO_CONFIG="$PREFIX/lib/cmake/zlib/ZLIBConfig.cmake"
    sed -i.bak 's/"shared" "static"/"static"/' "$PATH_TO_CONFIG"
fi
echo "Content of $PATH_TO_CONFIG after modification:"
cat "$PATH_TO_CONFIG"



# rename  lib/libz.so.1.3.2 to lib/libz.so and remove the IMPORTED_SONAME_RELEASE line from the cmake config file
if [ "$ZLIB_BUILD_SHARED" = "ON" ]; then
    ZLIB_SHARED_CMAKE_FILE="$PREFIX/lib/cmake/zlib/ZLIB-shared-release.cmake"
    VERSION_TO_REPLACE=$PKG_VERSION
    MAJOR_VERSION=$(echo $VERSION_TO_REPLACE | cut -d. -f1)
    sed -i.bak "s|/lib/libz\.so\.$VERSION_TO_REPLACE\"|/lib/libz.so\"|g" "$ZLIB_SHARED_CMAKE_FILE"
    sed -i.bak "s|IMPORTED_SONAME_RELEASE \"libz.so.$MAJOR_VERSION\"||g" "$ZLIB_SHARED_CMAKE_FILE"

    # show content of the cmake file for debugging
    echo "Content of $ZLIB_SHARED_CMAKE_FILE after modification:"
    cat "$ZLIB_SHARED_CMAKE_FILE"
fi


# rename versioned shared library to unversioned one
if [ "$ZLIB_BUILD_SHARED" = "ON" ]; then
    ZLIB_LIB_DIR="$PREFIX/lib"
    
    # rm symlink
    rm -f "$ZLIB_LIB_DIR/libz.so"

    # create backup of the actual shared lib
    cp "$ZLIB_LIB_DIR/libz.so.$PKG_VERSION" "$ZLIB_LIB_DIR/libz.so"

    # rename all leftofter shared libraries to unversioned ones
    rm -f $ZLIB_LIB_DIR/libz.so.*
fi


# fix broken pkg-config file
python - <<'PY'
from pathlib import Path
import os
prefix = os.environ.get("PREFIX")
p = Path(prefix) / "lib/pkgconfig/zlib.pc"
lines = p.read_text().splitlines()
lines[:2] = [f"prefix={prefix}", f"exec_prefix={prefix}"]
p.write_text("\n".join(lines) + "\n")
PY


# show pkg-config file for debugging
echo "Content of $PREFIX/lib/pkgconfig/zlib.pc after modification:"
cat "$PREFIX/lib/pkgconfig/zlib.pc"