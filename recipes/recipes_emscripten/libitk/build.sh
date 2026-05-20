#!/bin/bash
set -e

mkdir -p build
cd build




# add to cmake global include path
export CXXFLAGS="$CXXFLAGS -I${HDF5_INC_DIR}"
export CFLAGS="$CFLAGS -I${HDF5_INC_DIR}"
export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"


# delete shared libz
rm -f ${PREFIX}/lib/libz.so*

emcmake cmake ${CMAKE_ARGS} \
    -GNinja \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DBUILD_TESTING=OFF \
    -DModule_ITKTestKernel=OFF \
    -DModule_ITKIOTransformBase=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DITK_USE_GPU=OFF \
    -DITK_DEFAULT_THREADER=Platform \
    -DITK_USE_PTHREADS=OFF \
    -DITK_USE_OPENMP=OFF \
    -DModule_ITKTBBImageToImageFilter=OFF \
    -DITK_USE_FFTWD=OFF \
    -DITK_USE_FFTWF=OFF \
    -DITK_USE_SYSTEM_FFTW=OFF \
    -DITK_DYNAMIC_LOADING=OFF \
    -DITK_USE_SYSTEM_EXPAT=ON \
    -DITK_USE_SYSTEM_JPEG=ON \
    -D "CMAKE_BUILD_TYPE:STRING=RELEASE" \
    -D "CMAKE_FIND_ROOT_PATH:PATH=${PREFIX}" \
    -D "CMAKE_FIND_ROOT_PATH_MODE_INCLUDE:STRING=ONLY" \
    -D "CMAKE_FIND_ROOT_PATH_MODE_LIBRARY:STRING=ONLY" \
    -D "CMAKE_FIND_ROOT_PATH_MODE_PROGRAM:STRING=NEVER" \
    -D "CMAKE_FIND_ROOT_PATH_MODE_PACKAGE:STRING=ONLY" \
    -D "CMAKE_FIND_FRAMEWORK:STRING=NEVER" \
    -D "CMAKE_FIND_APPBUNDLE:STRING=NEVER" \
    -D "CMAKE_INSTALL_PREFIX=${PREFIX}" \
    -D "CMAKE_PROGRAM_PATH=${BUILD_PREFIX}" \
    -DITK_USE_SYSTEM_PNG=ON \
    -DITK_USE_SYSTEM_TIFF=ON \
    -DITK_USE_SYSTEM_ZLIB=ON \
    -DITK_USE_SYSTEM_EIGEN=ON \
    -DITK_BUILD_DEFAULT_MODULES=OFF \
    -DModule_ITKReview=OFF \
    -DModule_ITKTBB=OFF \
    -DModule_ITKIOTransformHDF5=OFF \
    -DModule_ITKTransformIO=ON \
    -DModule_ITKDisplacementFields=ON \
    -DModule_ITKCommon=ON \
    -DModule_ITKDisplacementField=ON \
    -DModule_ITKIOGDCM=ON \
    -DModule_ITKIOImageBase=ON \
    -DModule_ITKIOTransformBase=ON \
    -DModule_ITKImageCompose=ON \
    -DModule_ITKImageIntensity=ON \
    -DModule_ITKLabelMap=ON \
    -DModule_ITKMetricsv4=ON \
    -DModule_ITKOptimizersv4=ON \
    -DModule_ITKRegistrationMethodsv4=ON \
    -DModule_ITKTransform=ON \
    -DModule_ITKHDF5=OFF \
    -DModule_ITKIOTransformFactory=OFF \
    -DITK_FORBID_DOWNLOADS=ON \
    -DDO_NOT_BUILD_ITK_TEST_DRIVER=ON \
    "${SRC_DIR}"

ninja -j${CPU_COUNT}
ninja install
