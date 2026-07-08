#!/bin/bash
set -euo pipefail

move_dir_contents() {
    local src_dir="$1"
    local dst_dir="$2"

    if [ -d "${src_dir}" ]; then
        mv "${src_dir}"/* "${dst_dir}/" 2>/dev/null || true
        rmdir "${src_dir}" 2>/dev/null || true
    fi
}

rewrite_cmake_exports() {
    local expr="$1"

    find "${PREFIX}/lib/cmake/opencv5" -type f -name "*.cmake" \
        -exec sed -i "${expr}" {} + 2>/dev/null || true
}

mkdir -p _build
cd _build

TARGET_PYTHON_SITE_PACKAGES="${PREFIX}/lib/python${PY_VER}/site-packages"
TARGET_PYTHON_EXT_SUFFIX=".cpython-${PY_VER/./}-wasm32-emscripten.so"
TARGET_PYTHON_LOADER_DIR="${TARGET_PYTHON_SITE_PACKAGES}/cv2/python-${PY_VER}"
BUILD_PYTHON="${BUILD_PREFIX}/bin/python"
TARGET_PYTHON_INCLUDE="${PREFIX}/include/python${PY_VER}"
TARGET_PYTHON_LIB="${PREFIX}/lib/libpython${PY_VER}.a"
TARGET_NUMPY_INCLUDE="${TARGET_PYTHON_SITE_PACKAGES}/numpy/_core/include"

export CFLAGS="${CFLAGS:-} $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS:-} $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
export LDFLAGS="${LDFLAGS:-} $EM_FORGE_SIDE_MODULE_LDFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"

cmake_args=(
    -GNinja
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="${PREFIX}"
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_PREFIX_PATH="${PREFIX}"
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS"
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS"
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH
    -DPython3_EXECUTABLE="${BUILD_PYTHON}"
    -DPython3_INCLUDE_DIR="${TARGET_PYTHON_INCLUDE}"
    -DPython3_INCLUDE_DIRS="${TARGET_PYTHON_INCLUDE}"
    -DPython3_LIBRARY="${TARGET_PYTHON_LIB}"
    -DPython3_LIBRARIES="${TARGET_PYTHON_LIB}"
    -DPYTHON3_EXECUTABLE="${BUILD_PYTHON}"
    -DPYTHON3_INCLUDE_DIR="${TARGET_PYTHON_INCLUDE}"
    -DPYTHON3_INCLUDE_PATH="${TARGET_PYTHON_INCLUDE}"
    -DPYTHON3_INCLUDE_DIRS="${TARGET_PYTHON_INCLUDE}"
    -DPYTHON3_LIBRARY="${TARGET_PYTHON_LIB}"
    -DPYTHON3_LIBRARIES="${TARGET_PYTHON_LIB}"
    -DPYTHON_DEFAULT_EXECUTABLE="${BUILD_PYTHON}"
    -DPython3_NumPy_INCLUDE_DIRS="${TARGET_NUMPY_INCLUDE}"
    -DPYTHON3_NUMPY_INCLUDE_DIR="${TARGET_NUMPY_INCLUDE}"
    -DPYTHON3_NUMPY_INCLUDE_DIRS="${TARGET_NUMPY_INCLUDE}"
    -DPYTHON3_PACKAGES_PATH="lib/python${PY_VER}/site-packages"
    -DPYTHON3_CVPY_SUFFIX="${TARGET_PYTHON_EXT_SUFFIX}"
    -DOPENCV_PYTHON_INSTALL_PATH="lib/python${PY_VER}/site-packages"
    -DOPENCV_PYTHON3_INSTALL_PATH="lib/python${PY_VER}/site-packages"
    -DOPENCV_PYTHON_SKIP_LINKER_EXCLUDE_LIBS=ON
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"
    -DBUILD_SHARED_LIBS=OFF
    -DENABLE_PIC=FALSE
    -DCPU_BASELINE=
    -DCPU_DISPATCH=
    -DCV_TRACE=OFF
    -DCV_ENABLE_INTRINSICS=ON
    -DENABLE_PRECOMPILED_HEADERS=OFF
)

cmake_args+=(
    -DWITH_LAPACK=OFF
    -DWITH_ITT=OFF
    -DWITH_IPP=OFF
    -DWITH_TBB=OFF
    -DWITH_PTHREADS_PF=OFF
    -DWITH_OPENMP=OFF
    -DWITH_OPENCL=OFF
    -DWITH_OPENGL=OFF
    -DWITH_1394=OFF
    -DWITH_FFMPEG=OFF
    -DWITH_GSTREAMER=OFF
    -DWITH_V4L=OFF
    -DWITH_DSHOW=OFF
    -DWITH_MSMF=OFF
    -DWITH_GTK=OFF
    -DWITH_QT=OFF
    -DWITH_WIN32UI=OFF
    -DWITH_VTK=OFF
    -DWITH_EIGEN=ON
    -DWITH_CUDA=OFF
    -DWITH_VULKAN=OFF
    -DWITH_OPENVX=OFF
    -DWITH_OPENNI=OFF
    -DWITH_OPENNI2=OFF
    -DWITH_GDAL=ON
    -DWITH_GDCM=ON
    -DWITH_GPHOTO2=OFF
    -DWITH_XIMEA=OFF
    -DWITH_UEYE=OFF
    -DWITH_ARAVIS=OFF
    -DWITH_PVAPI=OFF
    -DWITH_OBSENSOR=OFF
    -DWITH_CAROTENE=OFF
    -DWITH_FASTCV=OFF
    -DWITH_ARMPL=OFF
    -DWITH_OPENVINO=OFF
    -DWITH_ONNXRUNTIME=OFF
    -DWITH_WEBNN=OFF
    -DWITH_TIMVX=OFF
    -DWITH_CANN=OFF
    -DWITH_OPENEXR=OFF
    -DWITH_AVIF=OFF
    -DWITH_SPNG=OFF
    -DWITH_JPEGXL=OFF
    -DWITH_ZLIB_NG=OFF
    -DWITH_CLP=OFF
    -DWITH_QUIRC=OFF
    -DWITH_JASPER=ON
    -DWITH_UNIFONT=OFF
    -DWITH_PROTOBUF=ON
    -DWITH_FLATBUFFERS=ON
)

cmake_args+=(
    -DWITH_ZLIB=ON
    -DBUILD_ZLIB=OFF
    -DWITH_PNG=ON
    -DBUILD_PNG=OFF
    -DWITH_JPEG=ON
    -DBUILD_JPEG=OFF
    -DWITH_TIFF=ON
    -DBUILD_TIFF=OFF
    -DWITH_WEBP=ON
    -DBUILD_WEBP=OFF
    -DWITH_OPENJPEG=ON
    -DBUILD_OPENJPEG=OFF
    -DWITH_IMGCODEC_GIF=ON
    -DWITH_IMGCODEC_HDR=ON
    -DWITH_IMGCODEC_PXM=ON
    -DWITH_IMGCODEC_PFM=ON
    -DWITH_IMGCODEC_SUNRASTER=ON
)

cmake_args+=(
    -DBUILD_opencv_core=ON
    -DBUILD_opencv_imgproc=ON
    -DBUILD_opencv_imgcodecs=ON
    -DBUILD_opencv_flann=ON
    -DBUILD_opencv_features=ON
    -DBUILD_opencv_3d=ON
    -DBUILD_opencv_photo=ON
    -DBUILD_opencv_python3=ON
    -DBUILD_opencv_dnn=OFF
    -DBUILD_opencv_highgui=OFF
    -DBUILD_opencv_videoio=ON
    -DBUILD_opencv_video=ON
    -DBUILD_opencv_videostab=ON
    -DBUILD_opencv_shape=ON
    -DBUILD_opencv_stitching=ON
    -DBUILD_opencv_objdetect=ON
    -DBUILD_opencv_superres=OFF
    -DBUILD_opencv_ml=OFF
    -DBUILD_opencv_gapi=ON
    -DBUILD_opencv_js=OFF
    -DBUILD_opencv_java=OFF
    -DBUILD_opencv_apps=OFF
)

cmake_args+=(
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_PERF_TESTS=OFF
    -DBUILD_DOCS=OFF
    -DBUILD_PACKAGE=OFF
    -DOPENCV_ENABLE_NONFREE=OFF
    -DOPENCV_GENERATE_PKGCONFIG=OFF
    -DOPENCV_GENERATE_SETUPVARS=OFF
    -DOPENCV_ENABLE_MEMORY_SANITIZER=OFF
    -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=OFF
    -DOPENCV_DISABLE_THREAD_SUPPORT=OFF
    -DENABLE_CONFIG_VERIFICATION=OFF
    ..
)

emcmake cmake "${cmake_args[@]}"

ninja install

# OpenCV 5 installs under versioned subdirectories for side-by-side installs.
# Fix up the layout. All steps are best-effort (non-fatal).

# 1. Headers: include/opencv5/opencv2/ -> include/opencv2/
move_dir_contents "${PREFIX}/include/opencv5" "${PREFIX}/include"

# 2. 3rdparty libs: lib/opencv5/3rdparty/ -> lib/
move_dir_contents "${PREFIX}/lib/opencv5/3rdparty" "${PREFIX}/lib"
# Also move any main-level versioned libs: lib/opencv5/libopencv_*.a -> lib/
if [ -d "${PREFIX}/lib/opencv5" ]; then
    mv "${PREFIX}/lib/opencv5"/libopencv_*.a "${PREFIX}/lib/" 2>/dev/null || true
    rmdir "${PREFIX}/lib/opencv5" 2>/dev/null || true
fi

# 3. Fix paths in CMake config
if [ -d "${PREFIX}/lib/cmake/opencv5" ]; then
    # Fix all versioned path references: eliminate /opencv5/ segments
    # Pattern A: .../opencv5/...  -> .../...
    rewrite_cmake_exports 's|/opencv5/|/|g'
    # Pattern B: include/opencv5/ (no leading slash, e.g. in INTERFACE_INCLUDE_DIRECTORIES)
    rewrite_cmake_exports 's|include/opencv5/|include/|g'
    # Pattern C: isolated ".../opencv5" at end of path (quoted string, no trailing slash)
    rewrite_cmake_exports 's|/include/opencv5"|/include"|g'
    rewrite_cmake_exports 's|/lib/opencv5"|/lib"|g'
    # Pattern D: leftover /3rdparty/ from moved 3rdparty libs
    rewrite_cmake_exports 's|/3rdparty/|/|g'
    # The package itself is built as side modules, but downstream test executables
    # must not inherit SIDE_MODULE link flags from imported OpenCV targets.
    rewrite_cmake_exports 's|-sSIDE_MODULE=1||g'
    rewrite_cmake_exports 's|-sSIDE_MODULE||g'
    rewrite_cmake_exports 's|SIDE_MODULE=1||g'
    # Fix libz.so -> libz.a (zlib recipe provides .so, but wasm-ld needs .a)
    rewrite_cmake_exports 's|libz\.so|libz.a|g'
    # OpenCV's exported package can spell protobuf static archives as
    # liblibprotobuf*.a even though the libprotobuf recipe installs the
    # canonical libprotobuf*.a names.
    rewrite_cmake_exports 's|liblibprotobuf-lite\.a|libprotobuf-lite.a|g'
    rewrite_cmake_exports 's|liblibprotobuf\.a|libprotobuf.a|g'
    # GDAL's static archive depends on several static libraries, but the
    # generated OpenCV exports do not propagate them for downstream consumers.
    rewrite_cmake_exports 's|lib/libgdal\.a|lib/libgdal.a;${_IMPORT_PREFIX}/lib/libgeos_c.a;${_IMPORT_PREFIX}/lib/libgeos.a;${_IMPORT_PREFIX}/lib/libproj.a;${_IMPORT_PREFIX}/lib/libiconv.a;${_IMPORT_PREFIX}/lib/libsqlite3.a|g'
    # Fix missing libsharpyuv.a in exported imgcodecs dependencies.
    # OpenCV links libwebp, but libwebp itself requires sharpyuv and that
    # dependency is not propagated in the generated OpenCV CMake exports.
    rewrite_cmake_exports 's|lib/libwebp\.a|lib/libwebp.a;${_IMPORT_PREFIX}/lib/libsharpyuv.a|g'
fi

# 4. Remove Python bytecode caches from the staged package.
if [ -d "${TARGET_PYTHON_SITE_PACKAGES}/cv2" ]; then
    find "${TARGET_PYTHON_SITE_PACKAGES}/cv2" -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
fi

# 5. Emscripten/CMake archives the Python extension target instead of linking a
# real wasm side module. Re-link it manually into a loadable module.
python_archive="${PWD}/lib/opencv_python3${TARGET_PYTHON_EXT_SUFFIX}"
if [ -f "${python_archive}" ]; then
    opencv_python_libs=()
    while IFS= read -r -d '' lib; do
        opencv_python_libs+=("${lib}")
    done < <(find "${PWD}/lib" -maxdepth 1 -type f -name 'libopencv_*.a' -print0 | sort -z)
    if [ -f "${PWD}/3rdparty/lib/liblibopenjp2.a" ]; then
        opencv_python_libs+=("${PWD}/3rdparty/lib/liblibopenjp2.a")
    fi

    transitive_codec_libs=()
    for candidate in \
        "${PREFIX}/lib/libjpeg.a" \
        "${PREFIX}/lib/libpng.a" \
        "${PREFIX}/lib/libtiff.a" \
        "${PREFIX}/lib/libwebp.a" \
        "${PREFIX}/lib/libwebpmux.a" \
        "${PREFIX}/lib/libwebpdemux.a" \
        "${PREFIX}/lib/libsharpyuv.a" \
        "${PREFIX}/lib/libz.a" \
        "${PREFIX}/lib/libz.so"; do
        if [ -f "${candidate}" ]; then
            transitive_codec_libs+=("${candidate}")
        fi
    done

    transitive_gdal_libs=()
    for candidate in \
        "${PREFIX}/lib/libade.a" \
        "${PREFIX}/lib/libgdal.a" \
        "${PREFIX}/lib/libgeos_c.a" \
        "${PREFIX}/lib/libgeos.a" \
        "${PREFIX}/lib/libproj.a" \
        "${PREFIX}/lib/libiconv.a" \
        "${PREFIX}/lib/libsqlite3.a"; do
        if [ -f "${candidate}" ]; then
            transitive_gdal_libs+=("${candidate}")
        fi
    done

    em++ \
        ${EM_FORGE_SIDE_MODULE_LDFLAGS} \
        -sSUPPORT_LONGJMP=wasm \
        -fwasm-exceptions \
        -Wl,--whole-archive "${python_archive}" -Wl,--no-whole-archive \
        -Wl,--start-group \
        "${opencv_python_libs[@]}" \
        "${transitive_codec_libs[@]}" \
        "${transitive_gdal_libs[@]}" \
        -Wl,--end-group \
        -o "${TARGET_PYTHON_SITE_PACKAGES}/opencv_python3${TARGET_PYTHON_EXT_SUFFIX}"
fi

# 6. Move the loadable extension into the loader path with the canonical cv2
# name expected by cv2/__init__.py.
if [ -f "${TARGET_PYTHON_SITE_PACKAGES}/opencv_python3${TARGET_PYTHON_EXT_SUFFIX}" ]; then
    mkdir -p "${TARGET_PYTHON_LOADER_DIR}"
    mv \
        "${TARGET_PYTHON_SITE_PACKAGES}/opencv_python3${TARGET_PYTHON_EXT_SUFFIX}" \
        "${TARGET_PYTHON_LOADER_DIR}/cv2${TARGET_PYTHON_EXT_SUFFIX}"
fi

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
