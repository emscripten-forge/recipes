#!/bin/bash

mkdir build
cd build

BUILD_CONFIG=Release

if [[ ${PY3K} -eq 1 ]]; then
    ADDITIONAL_CMAKE_FLAGS="$ADDITIONAL_CMAKE_FLAGS -DPYTHON_VERSION_MAJOR=3 "
else
    ADDITIONAL_CMAKE_FLAGS="$ADDITIONAL_CMAKE_FLAGS -DPYTHON_VERSION_MAJOR=2 "
fi

mkdir -p "${PREFIX}/lib/pkgconfig"

cat > "${PREFIX}/lib/pkgconfig/openssl.pc" <<EOF
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: OpenSSL
Description: Secure Sockets Layer and cryptography libraries
Version: $(openssl version | awk '{print $2}')

Requires:
Libs: -L\${libdir} -lssl -lcrypto
Libs.private: -ldl -lpthread
Cflags: -I\${includedir}
EOF


cat > "${PREFIX}/lib/pkgconfig/uuid.pc" <<EOF
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: UUID
Description: Universally unique identifier library
Version: 1.0

Requires:
Libs: -L\${libdir} -luuid
Cflags: -I\${includedir}
EOF

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH

# test pkg-config can find openssl
pkg-config --libs openssl


 
emcmake cmake ..  $CMAKE_ARGS \
    -Wno-dev \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DCMAKE_BUILD_TYPE=$BUILD_CONFIG \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX:PATH="$PREFIX" \
    -DCMAKE_INSTALL_RPATH:PATH="$PREFIX/lib" \
    -DGDCM_USE_SYSTEM_EXPAT:BOOL=ON \
    -DGDCM_USE_SYSTEM_ZLIB:BOOL=ON \
    -DGDCM_USE_SYSTEM_UUID:BOOL=ON \
    -DGDCM_USE_SYSTEM_OPENJPEG:BOOL=ON \
    -DGDCM_USE_SYSTEM_OPENSSL:BOOL=ON \
    -DGDCM_USE_SYSTEM_JSON:BOOL=ON \
    -DGDCM_BUILD_SHARED_LIBS:BOOL=ON \
    -DGDCM_BUILD_APPLICATIONS:BOOL=OFF \
    -DGDCM_BUILD_TESTING:BOOL=OFF \
    -DGDCM_BUILD_EXAMPLES:BOOL=OFF \
    -DGDCM_BUILD_APPLICATIONS=OFF \
    -DGDCM_USE_VTK:BOOL=OFF \
    -DGDCM_WRAP_PYTHON:BOOL=ON \
    -DGDCM_DOCUMENTATION:BOOL=OFF \
    -DGDCM_BUILD_DOCBOOK_MANPAGES:BOOL=OFF \
    -DSWIG_EXECUTABLE:FILEPATH=${BUILD_PREFIX}/bin/swig \
    -DGDCM_INSTALL_PYTHONMODULE_DIR:PATH=$SP_DIR \
    -DGDCM_INSTALL_NO_DOCUMENTATION:BOOL=ON \
    -DGDCM_INSTALL_NO_DEVELOPMENT:BOOL=ON \
    -DOPENSSL_ROOT_DIR=${PREFIX} \
    -DOPENSSL_INCLUDE_DIR=${PREFIX}/include \
    -DOPENSSL_LIBRARY=${PREFIX}/lib/libssl.a \
    -DOPENSSL_LIBRARIES=${PREFIX}/lib/libssl.a \
    -DOPENSSL_SSL_LIBRARY=${PREFIX}/lib/libssl.a \
    -DOPENSSL_SSL_LIBRARIES=${PREFIX}/lib/libssl.a \
    -DOPENSSL_CRYPTO_LIBRARY=${PREFIX}/lib/libcrypto.a \
    -DOPENSSL_CRYPTO_LIBRARIES=${PREFIX}/lib/libcrypto.a \
    -DOPENSSL_USE_STATIC_LIBS=ON \
    -DUUID_INCLUDE_DIR=${PREFIX}/include \
    -DUUID_LIBRARY=${PREFIX}/lib/libuuid.a \
    -DUUID_LIBRARIES=${PREFIX}/lib/libuuid.a \
    -DEXPAT_INCLUDE_DIR=${PREFIX}/include \
    -DEXPAT_LIBRARY=${PREFIX}/lib/libexpat.a \
    -DEXPAT_LIBRARIES=${PREFIX}/lib/libexpat.a \
    -DJSON_INCLUDE_DIR=${PREFIX}/include \
    -DJSON_LIBRARY=${PREFIX}/lib/libjson-c.a \
    -DJSON_LIBRARIES=${PREFIX}/lib/libjson-c.a \
    -DPYTHON_LIBRARY=${PREFIX}/lib/libpython${PY_VER}.a \
    -DPYTHON_INCLUDE_DIR=${PREFIX}/include/python${PY_VER} \
    -DSWIG_PYTHON_LEGACY_BOOL=OFF \
    $ADDITIONAL_CMAKE_FLAGS


find . -name "gdcmswigPYTHON_wrap.cxx" -exec sed -i \
  's/PyEval_CallObject/PyObject_CallObject/g' {} +

emmake make -j$CPU_COUNT install