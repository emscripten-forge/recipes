#!/bin/bash
set -euxo pipefail

# HDF5 (C library and high-level library, no tools) as static archives, for
# programs linked as a whole. Not thread-safe and without threads, so the
# objects have no atomics or TLS and link into programs with or without
# pthreads. Installed in its own directories, next to the hdf5 package
# rather than in place of it.
NAME="${PKG_NAME}"            # hdf5-static

emcmake cmake -S . -B _build -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DHDF5_INSTALL_INCLUDE_DIR="include/$NAME" \
    -DHDF5_INSTALL_LIB_DIR="lib/$NAME" \
    -DHDF5_INSTALL_CMAKE_DIR="lib/$NAME/cmake" \
    -DHDF5_INSTALL_DATA_DIR="share/$NAME" \
    -DHDF5_INSTALL_BIN_DIR="lib/$NAME/bin" \
    -DCMAKE_C_FLAGS="-Wno-incompatible-pointer-types-discards-qualifiers" \
    -DCMAKE_EXE_LINKER_FLAGS="-sNODERAWFS=1 -sFORCE_FILESYSTEM=1" \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DONLY_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DHDF5_BUILD_EXAMPLES=OFF -DHDF5_BUILD_TOOLS=OFF -DHDF5_BUILD_UTILS=OFF \
    -DHDF5_BUILD_HL_LIB=ON -DHDF5_BUILD_FORTRAN=OFF -DHDF5_BUILD_CPP_LIB=OFF \
    -DHDF5_BUILD_JAVA=OFF -DHDF5_ENABLE_THREADSAFE=OFF \
    -DHDF5_ENABLE_Z_LIB_SUPPORT=ON -DHDF5_ENABLE_SZIP_SUPPORT=OFF \
    -DHDF5_ENABLE_ROS3_VFD=OFF -DHDF5_ENABLE_PARALLEL=OFF \
    -DH5_HAVE_GETPWUID=OFF -DH5_HAVE_SIGNAL=OFF \
    -DZLIB_USE_EXTERNAL=OFF \
    -DZLIB_INCLUDE_DIR="$PREFIX/include" \
    -DZLIB_LIBRARY="$PREFIX/lib/libz.a"
$(which cmake) --build _build -j"${CPU_COUNT:-2}"
$(which cmake) --install _build
# h5cc & co. compile with the build's paths: of no use here
rm -rf "$PREFIX/lib/$NAME/bin"

# HDF5's own pkg-config files stay in lib/hdf5-static/pkgconfig; this one,
# named after the package, is what consumers use
mkdir -p "$PREFIX/lib/pkgconfig" "$PREFIX/share/licenses/$NAME"
cat > "$PREFIX/lib/pkgconfig/$NAME.pc" <<EOF
prefix=$PREFIX
includedir=\${prefix}/include/$NAME
libdir=\${prefix}/lib/$NAME

Name: $NAME
Description: HDF5 C and high-level libraries, static, for emscripten-wasm32
Version: $PKG_VERSION
Requires.private: zlib
Libs: -L\${libdir} -lhdf5_hl -lhdf5
Cflags: -I\${includedir}
EOF
# programs that link the archives in ship this notice
install -m 644 COPYING "$PREFIX/share/licenses/$NAME/COPYING"
