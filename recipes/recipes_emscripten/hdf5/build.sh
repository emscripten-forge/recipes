mkdir build
cd build

export LDFLAGS="-sNODERAWFS=1 -sUSE_ZLIB=1 -sFORCE_FILESYSTEM=1"

cp ${RECIPE_DIR}/settings/* ../src/

emcmake cmake .. \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DH5_HAVE_GETPWUID=OFF \
    -DH5_HAVE_SIGNAL=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DONLY_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_C_FLAGS="-fPIC -Wno-incompatible-pointer-types-discards-qualifiers" \
    -DCMAKE_CXX_FLAGS="-fPIC -Wno-incompatible-pointer-types-discards-qualifiers" \
    -DCMAKE_SHARED_LINKER_FLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS} -s NODERAWFS=1 -sFORCE_FILESYSTEM=1" \
    -DHDF5_BUILD_EXAMPLES=OFF \
    -DHDF5_BUILD_TOOLS=OFF \
    -DHDF5_BUILD_UTILS=OFF \
    -DHDF5_ENABLE_Z_LIB_SUPPORT=ON \
    -DHDF5_ENABLE_ROS3_VFD=OFF \
    -DZLIB_INCLUDE_DIR=${PREFIX}/include \
    -DZLIB_LIBRARY=${PREFIX}/lib/libz.a

cp ${RECIPE_DIR}/settings/* ../src/
cp ${RECIPE_DIR}/settings/* src/

emmake make -j 4
emmake make install
