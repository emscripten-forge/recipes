#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"

mkdir -p build
mkdir -p build/disabled_vendor_headers

emcmake cmake -S litert -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX};${BUILD_PREFIX}" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_CROSSCOMPILING_EMULATOR=node \
    -DOVERRIDABLE_FETCH_CONTENT_GIT_REPOSITORY_AND_TAG_TO_URL=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DLITERT_BUILD_TESTS=OFF \
    -DLITERT_ENABLE_GPU=OFF \
    -DLITERT_ENABLE_NPU=OFF \
    -DLITERT_ENABLE_QUALCOMM=OFF \
    -DLITERT_ENABLE_SAMSUNG=OFF \
    -DNEUROPILOT_HEADERS_DIR="${SRC_DIR}/build/disabled_vendor_headers" \
    -DQAIRT_HEADERS_DIR="${SRC_DIR}/build/disabled_vendor_headers" \
    -DLITECORE_HEADERS_DIR="${SRC_DIR}/build/disabled_vendor_headers" \
    -DTENSORFLOW_SOURCE_DIR="${SRC_DIR}/third_party/tensorflow" \
    -DTFLITE_ENABLE_GPU=OFF \
    -DTFLITE_ENABLE_XNNPACK=OFF \
    -DTFLITE_HOST_TOOLS_DIR="${BUILD_PREFIX}/bin"

emmake ninja -C build -j"${CPU_COUNT}" \
    tensorflow-lite \
    litert_c_api \
    litert_cc_api \
    litert_cc_internal \
    litert_core \
    litert_core_model \
    litert_logging \
    litert_runtime

mkdir -p "${PREFIX}/include"
find litert -type f \( -name '*.h' -o -name '*.hpp' \) -exec cp --parents "{}" "${PREFIX}/include/" \;
cp -R build/include/. "${PREFIX}/include/"

mkdir -p "${PREFIX}/lib"
for lib_name in \
    libtensorflow-lite.a \
    liblitert_c_api.a \
    liblitert_cc_api.a \
    liblitert_cc_internal.a \
    liblitert_core.a \
    liblitert_core_model.a \
    liblitert_logging.a \
    liblitert_runtime.a
do
    lib_path=$(find build -name "${lib_name}" -print -quit)
    if [[ -z "${lib_path}" ]]; then
        echo "Missing expected library ${lib_name}" >&2
        exit 1
    fi
    cp "${lib_path}" "${PREFIX}/lib/"
done

mkdir -p "${PREFIX}/lib/cmake/litert"
cat > "${PREFIX}/lib/cmake/litert/litertConfig.cmake" <<'EOF'
get_filename_component(_LITERT_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_LITERT_IMPORT_PREFIX "${_LITERT_IMPORT_PREFIX}" PATH)
get_filename_component(_LITERT_IMPORT_PREFIX "${_LITERT_IMPORT_PREFIX}" PATH)
get_filename_component(_LITERT_IMPORT_PREFIX "${_LITERT_IMPORT_PREFIX}" PATH)

set(_LITERT_INCLUDE_DIR "${_LITERT_IMPORT_PREFIX}/include")
set(LITERT_STATIC_LIBRARIES
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_cc_api.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_c_api.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_cc_internal.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_core.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_core_model.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_logging.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_runtime.a"
    "${_LITERT_IMPORT_PREFIX}/lib/libtensorflow-lite.a"
)

foreach(_litert_lib IN LISTS LITERT_STATIC_LIBRARIES)
    if(NOT EXISTS "${_litert_lib}")
        message(FATAL_ERROR "litert: expected library not found at ${_litert_lib}")
    endif()
endforeach()

if(NOT TARGET litert::litert_cc_headers)
    add_library(litert::litert_cc_headers INTERFACE IMPORTED)
    set_target_properties(litert::litert_cc_headers PROPERTIES
        INTERFACE_COMPILE_FEATURES cxx_std_20
        INTERFACE_INCLUDE_DIRECTORIES "${_LITERT_INCLUDE_DIR}"
    )
endif()

if(NOT TARGET litert::litert_cc_api)
    add_library(litert::litert_cc_api INTERFACE IMPORTED)
    set_target_properties(litert::litert_cc_api PROPERTIES
        INTERFACE_COMPILE_FEATURES cxx_std_20
        INTERFACE_INCLUDE_DIRECTORIES "${_LITERT_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "litert::litert_cc_headers;${LITERT_STATIC_LIBRARIES}"
    )

    if(EMSCRIPTEN)
        set_property(TARGET litert::litert_cc_api APPEND PROPERTY
            INTERFACE_LINK_OPTIONS
                -sUSE_WEBGPU=1
                -sALLOW_MEMORY_GROWTH=1
        )
    endif()
endif()

set(LITERT_INCLUDE_DIRS "${_LITERT_INCLUDE_DIR}")
set(LITERT_LIBRARIES "${LITERT_STATIC_LIBRARIES}")
set(LITERT_VERSION "2.1.5")

unset(_LITERT_IMPORT_PREFIX)
unset(_LITERT_INCLUDE_DIR)
unset(_litert_lib)
EOF