mkdir build
cd build

export LDFLAGS="-sNODERAWFS=1 -sUSE_ZLIB=1 -sFORCE_FILESYSTEM=1"

emcmake cmake .. -GNinja \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DH5_HAVE_GETPWUID=0 \
    -DH5_HAVE_SIGNAL=0 \
    -DBUILD_SHARED_LIBS=0 \
    -DBUILD_STATIC_LIBS=1 \
    -DBUILD_TESTING=0 \
    -DCMAKE_C_FLAGS="-Wno-incompatible-pointer-types-discards-qualifiers" \
    -DHDF5_BUILD_EXAMPLES=0 \
    -DHDF5_BUILD_TOOLS=0 \
    -DHDF5_BUILD_UTILS=0 \
    -DHDF5_ENABLE_Z_LIB_SUPPORT=1 \
    -DHDF5_ENABLE_ROS3_VFD=0

ninja
ninja install
