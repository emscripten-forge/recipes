#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

set -x

PARALLEL=""

CMAKE_BUILD_TYPE=Release

# 2022/04/25
# DAP Remote tests are causing spurious failures at the momment
# https://github.com/Unidata/netcdf-c/issues/2188#issuecomment-1015927961
# -DENABLE_DAP_REMOTE_TESTS=OFF
# Build static.

# Set these manually
# * HDF5_C_LIBRARY
# * HDF5_HL_LIBRARY
# * HDF5_LIBRARIES
# * HDF5_INCLUDE_DIR

cmake ${CMAKE_ARGS} -GNinja -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR="lib" \
      -DCMAKE_PREFIX_PATH=${PREFIX} \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DENABLE_DAP=OFF \
      -DENABLE_DAP_REMOTE_TESTS=OFF \
      -DENABLE_HDF4=OFF \
      -DENABLE_NETCDF_4=ON \
      -DBUILD_SHARED_LIBS=OFF \
      -DENABLE_TESTS=OFF \
      -DBUILD_UTILITIES=OFF \
      -DENABLE_DOXYGEN=OFF \
      -DENABLE_CDF5=ON \
      -DHDF5_C_LIBRARY=$PREFIX/lib/libhdf5.a \
      -DHDF5_HL_LIBRARY=$PREFIX/lib/libhdf5_hl.a \
      -DHDF5_INCLUDE_DIR=$PREFIX/include \
      -DHDF5_VERSION="1.12.2" \
      -DENABLE_BYTERANGE=ON \
      ${PARALLEL} \
      -DENABLE_NCZARR=on \
      -DENABLE_NCZARR_S3=off \
      -DENABLE_NCZARR_S3_TESTS=off \
      ${SRC_DIR}

ninja install -j${CPU_COUNT} ${VERBOSE_CM}

# Fix build paths in cmake artifacts
for fname in `ls ${PREFIX}/lib/cmake/netCDF/*`; do
    sed -i.bak "s#${CONDA_BUILD_SYSROOT}/usr/lib/lib\([a-z]*\).so#\1#g" ${fname}
    sed -i.bak "s#/Applications/Xcode_.*app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.*sdk/usr/lib/lib\([a-z]*\).dylib#\1#g" ${fname}
    rm ${fname}.bak
    cat ${fname}
done

# Fix build paths in nc-config
sed -i.bak "s#${BUILD_PREFIX}/bin/${CC}#${CC}#g" ${PREFIX}/bin/nc-config
rm ${PREFIX}/bin/nc-config.bak