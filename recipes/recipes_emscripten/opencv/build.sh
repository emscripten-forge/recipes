#!/bin/bash
set -e

mkdir -p _build
cd _build

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"

emcmake cmake -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS" \
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS" \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_PIC=FALSE \
    -DCPU_BASELINE='' \
    -DCPU_DISPATCH='' \
    -DCV_TRACE=OFF \
    -DCV_ENABLE_INTRINSICS=OFF \
    -DENABLE_PRECOMPILED_HEADERS=OFF \
    -DWITH_LAPACK=OFF \
    -DWITH_ITT=OFF \
    -DWITH_IPP=OFF \
    -DWITH_TBB=OFF \
    -DWITH_PTHREADS_PF=OFF \
    -DWITH_OPENMP=OFF \
    -DWITH_OPENCL=OFF \
    -DWITH_OPENGL=OFF \
    -DWITH_1394=OFF \
    -DWITH_FFMPEG=OFF \
    -DWITH_GSTREAMER=OFF \
    -DWITH_V4L=OFF \
    -DWITH_DSHOW=OFF \
    -DWITH_MSMF=OFF \
    -DWITH_GTK=OFF \
    -DWITH_QT=OFF \
    -DWITH_WIN32UI=OFF \
    -DWITH_VTK=OFF \
    -DWITH_EIGEN=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_VULKAN=OFF \
    -DWITH_OPENVX=OFF \
    -DWITH_OPENNI=OFF \
    -DWITH_OPENNI2=OFF \
    -DWITH_GDAL=OFF \
    -DWITH_GDCM=OFF \
    -DWITH_GPHOTO2=OFF \
    -DWITH_XIMEA=OFF \
    -DWITH_UEYE=OFF \
    -DWITH_ARAVIS=OFF \
    -DWITH_PVAPI=OFF \
    -DWITH_OBSENSOR=OFF \
    -DWITH_CAROTENE=OFF \
    -DWITH_FASTCV=OFF \
    -DWITH_ARMPL=OFF \
    -DWITH_OPENVINO=OFF \
    -DWITH_ONNXRUNTIME=OFF \
    -DWITH_WEBNN=OFF \
    -DWITH_TIMVX=OFF \
    -DWITH_CANN=OFF \
    -DWITH_OPENEXR=OFF \
    -DWITH_AVIF=OFF \
    -DWITH_SPNG=OFF \
    -DWITH_JPEGXL=OFF \
    -DWITH_ZLIB_NG=OFF \
    -DWITH_CLP=OFF \
    -DWITH_QUIRC=OFF \
    -DWITH_JASPER=OFF \
    -DWITH_UNIFONT=OFF \
    -DWITH_ZLIB=ON \
    -DBUILD_ZLIB=OFF \
    -DWITH_PNG=ON \
    -DBUILD_PNG=OFF \
    -DWITH_JPEG=ON \
    -DBUILD_JPEG=OFF \
    -DWITH_TIFF=ON \
    -DBUILD_TIFF=OFF \
    -DWITH_WEBP=ON \
    -DBUILD_WEBP=OFF \
    -DWITH_OPENJPEG=ON \
    -DBUILD_OPENJPEG=OFF \
    -DWITH_PROTOBUF=OFF \
    -DWITH_FLATBUFFERS=OFF \
    -DWITH_IMGCODEC_GIF=ON \
    -DWITH_IMGCODEC_HDR=ON \
    -DWITH_IMGCODEC_PXM=ON \
    -DWITH_IMGCODEC_PFM=ON \
    -DWITH_IMGCODEC_SUNRASTER=ON \
    -DBUILD_opencv_core=ON \
    -DBUILD_opencv_imgproc=ON \
    -DBUILD_opencv_imgcodecs=ON \
    -DBUILD_opencv_flann=ON \
    -DBUILD_opencv_features=ON \
    -DBUILD_opencv_3d=ON \
    -DBUILD_opencv_photo=ON \
    -DBUILD_opencv_dnn=OFF \
    -DBUILD_opencv_highgui=OFF \
    -DBUILD_opencv_videoio=OFF \
    -DBUILD_opencv_video=OFF \
    -DBUILD_opencv_videostab=OFF \
    -DBUILD_opencv_shape=OFF \
    -DBUILD_opencv_stitching=OFF \
    -DBUILD_opencv_objdetect=OFF \
    -DBUILD_opencv_superres=OFF \
    -DBUILD_opencv_ml=OFF \
    -DBUILD_opencv_gapi=OFF \
    -DBUILD_opencv_js=OFF \
    -DBUILD_opencv_python3=OFF \
    -DBUILD_opencv_java=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_PACKAGE=OFF \
    -DOPENCV_ENABLE_NONFREE=OFF \
    -DOPENCV_GENERATE_PKGCONFIG=OFF \
    -DOPENCV_GENERATE_SETUPVARS=OFF \
    -DOPENCV_ENABLE_MEMORY_SANITIZER=OFF \
    -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=OFF \
    -DOPENCV_DISABLE_THREAD_SUPPORT=OFF \
    -DENABLE_CONFIG_VERIFICATION=OFF \
    ..

ninja install

# OpenCV 5 installs under versioned subdirectories for side-by-side installs.
# Fix up the layout. All steps are best-effort (non-fatal).
# 1. Headers: include/opencv5/opencv2/ -> include/opencv2/
if [ -d "${PREFIX}/include/opencv5" ]; then
    mv "${PREFIX}/include/opencv5"/* "${PREFIX}/include/" 2>/dev/null || true
    rmdir "${PREFIX}/include/opencv5" 2>/dev/null || true
fi
# 2. Fix paths in CMake config
if [ -d "${PREFIX}/lib/cmake/opencv5" ]; then
    # Fix include paths (opencv5 -> standard)
    find "${PREFIX}/lib/cmake/opencv5" -type f -name "*.cmake" \
        -exec sed -i 's|include/opencv5/|include/|g' {} + 2>/dev/null || true
    find "${PREFIX}/lib/cmake/opencv5" -type f -name "*.cmake" \
        -exec sed -i 's|/include/opencv5/|/include/|g' {} + 2>/dev/null || true
    # Fix libz.so -> libz.a (zlib recipe provides .so, but wasm-ld needs .a)
    find "${PREFIX}/lib/cmake/opencv5" -type f -name "*.cmake" \
        -exec sed -i 's|libz\.so|libz.a|g' {} + 2>/dev/null || true
    # Fix missing libsharpyuv.a
    find "${PREFIX}/lib/cmake/opencv5" -type f -name "*.cmake" \
        -exec sed -i 's|\("${_IMPORT_PREFIX}/lib/libwebp\.a"\)|\1 "${_IMPORT_PREFIX}/lib/libsharpyuv.a"|g' {} + 2>/dev/null || true
fi

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
