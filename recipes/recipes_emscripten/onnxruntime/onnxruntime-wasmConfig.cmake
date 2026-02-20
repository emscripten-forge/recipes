# onnxruntime-wasmConfig.cmake
# CMake configuration file for onnxruntime-wasm (static WebAssembly build)
#
# Usage in consumer CMakeLists.txt:
#
#   find_package(onnxruntime-wasm REQUIRED)
#   target_link_libraries(my_target PRIVATE onnxruntime::onnxruntime_webassembly)
#
# This will automatically bring in the include directories and the Emscripten
# link options needed to build a working WASM binary.

cmake_minimum_required(VERSION 3.20)

# Compute the installation prefix from this file's location.
# Assumes the config is installed at:
#   ${PREFIX}/lib/cmake/onnxruntime-wasm/onnxruntime-wasmConfig.cmake
get_filename_component(_ORT_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "${_ORT_IMPORT_PREFIX}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "${_ORT_IMPORT_PREFIX}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "${_ORT_IMPORT_PREFIX}" PATH)

set(_ORT_LIB "${_ORT_IMPORT_PREFIX}/lib/libonnxruntime_webassembly.a")
set(_ORT_INCLUDE_DIR "${_ORT_IMPORT_PREFIX}/include")

# Verify the library is present
if(NOT EXISTS "${_ORT_LIB}")
    set(onnxruntime-wasm_FOUND FALSE)
    if(onnxruntime-wasm_FIND_REQUIRED)
        message(FATAL_ERROR "onnxruntime-wasm: library not found at ${_ORT_LIB}")
    elseif(NOT onnxruntime-wasm_FIND_QUIETLY)
        message(WARNING "onnxruntime-wasm: library not found at ${_ORT_LIB}")
    endif()
    return()
endif()

# Create the IMPORTED target
if(NOT TARGET onnxruntime::onnxruntime_webassembly)
    add_library(onnxruntime::onnxruntime_webassembly STATIC IMPORTED)

    set_target_properties(onnxruntime::onnxruntime_webassembly PROPERTIES
        IMPORTED_LOCATION "${_ORT_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${_ORT_INCLUDE_DIR}"
    )

    # Emscripten link options required when producing a standalone WASM binary.
    # Consumers that build shared-side-modules or Python extensions may need to
    # override / remove these according to their own linker requirements.
    if(EMSCRIPTEN)
        set_property(TARGET onnxruntime::onnxruntime_webassembly APPEND PROPERTY
            INTERFACE_LINK_OPTIONS
                -msimd128
                -sALLOW_MEMORY_GROWTH=1
                -sINITIAL_MEMORY=64MB
                -sEXIT_RUNTIME=1
        )
    endif()
endif()

# Version information
set(onnxruntime-wasm_VERSION "@VERSION@")
set(ONNXRUNTIME_WASM_VERSION "@VERSION@")

# Convenience / legacy variables
set(onnxruntime-wasm_FOUND TRUE)
set(ONNXRUNTIME_WASM_FOUND TRUE)
set(ONNXRUNTIME_WASM_INCLUDE_DIRS "${_ORT_INCLUDE_DIR}")
set(ONNXRUNTIME_WASM_LIBRARIES    "${_ORT_LIB}")

# Cleanup
unset(_ORT_IMPORT_PREFIX)
unset(_ORT_LIB)
unset(_ORT_INCLUDE_DIR)
