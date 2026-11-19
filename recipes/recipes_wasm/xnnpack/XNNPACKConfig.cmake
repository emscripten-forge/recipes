get_filename_component(_XNNPACK_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_XNNPACK_IMPORT_PREFIX "${_XNNPACK_IMPORT_PREFIX}" PATH)
get_filename_component(_XNNPACK_IMPORT_PREFIX "${_XNNPACK_IMPORT_PREFIX}" PATH)
get_filename_component(_XNNPACK_IMPORT_PREFIX "${_XNNPACK_IMPORT_PREFIX}" PATH)

set(_XNNPACK_INCLUDE_DIR "${_XNNPACK_IMPORT_PREFIX}/include")
set(_XNNPACK_LIB_DIR "${_XNNPACK_IMPORT_PREFIX}/lib")

if(NOT TARGET XNNPACK::xnnpack)
    add_library(XNNPACK::xnnpack STATIC IMPORTED)
    set_target_properties(XNNPACK::xnnpack PROPERTIES
        IMPORTED_LOCATION "${_XNNPACK_LIB_DIR}/libXNNPACK.a"
        INTERFACE_INCLUDE_DIRECTORIES "${_XNNPACK_INCLUDE_DIR}"
    )
endif()

if(NOT TARGET XNNPACK::xnnpack-microkernels-prod)
    add_library(XNNPACK::xnnpack-microkernels-prod STATIC IMPORTED)
    set_target_properties(XNNPACK::xnnpack-microkernels-prod PROPERTIES
        IMPORTED_LOCATION "${_XNNPACK_LIB_DIR}/libxnnpack-microkernels-prod.a"
    )
endif()

unset(_XNNPACK_IMPORT_PREFIX)
unset(_XNNPACK_INCLUDE_DIR)
unset(_XNNPACK_LIB_DIR)
