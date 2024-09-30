mkdir -p build
cd build

emcmake cmake .. \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DH5_HAVE_GETPWUID=OFF \
    -DH5_HAVE_SIGNAL=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DONLY_SHARED_LIBS=1 \
    -DBUILD_TESTING=OFF \
    -DCMAKE_C_FLAGS="-fPIC -Wno-incompatible-pointer-types-discards-qualifiers" \
    -DCMAKE_CXX_FLAGS="-fPIC -Wno-incompatible-pointer-types-discards-qualifiers" \
    -DCMAKE_SHARED_LINKER_FLAGS="${SIDE_MODULE_LDFLAGS} -s NODERAWFS=1 -sFORCE_FILESYSTEM=1" \
    -DHDF5_BUILD_EXAMPLES=OFF \
    -DHDF5_BUILD_TOOLS=OFF \
    -DHDF5_BUILD_UTILS=OFF \
    -DHDF5_ENABLE_Z_LIB_SUPPORT=1 \
    -DHDF5_ENABLE_ROS3_VFD=OFF \
    -DZLIB_INCLUDE_DIR=${PREFIX}/include \
    -DZLIB_LIBRARY=${PREFIX}/lib/libz_static.a


# https://github.com/pyodide/pyodide/blob/3222f2ed2d57bd34a8b55276c0cb333997843c42/packages/libhdf5/meta.yaml#L43-L49
cp ${RECIPE_DIR}/settings/* src/

emmake make -j${CPU_COUNT} install
