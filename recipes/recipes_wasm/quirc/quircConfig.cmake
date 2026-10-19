# quircConfig.cmake
# CMake configuration file for quirc

include(CMakeFindDependencyMacro)

# Compute the installation prefix relative to this file
# Assumes config is installed at: ${PREFIX}/lib/cmake/quirc/quircConfig.cmake
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)

set(_QUIRC_LIB "${_IMPORT_PREFIX}/lib/libquirc.a")
if(NOT EXISTS "${_QUIRC_LIB}")
    set(quirc_FOUND FALSE)
    if(quirc_FIND_REQUIRED)
        message(FATAL_ERROR "quirc library not found at ${_QUIRC_LIB}")
    elseif(NOT quirc_FIND_QUIETLY)
        message(WARNING "quirc library not found at ${_QUIRC_LIB}")
    endif()
    return()
endif()

# Create imported target
if(NOT TARGET quirc::quirc)
    add_library(quirc::quirc STATIC IMPORTED)

    set_target_properties(quirc::quirc PROPERTIES
        IMPORTED_LOCATION "${_QUIRC_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
    )
endif()

set(QUIRC_VERSION "@VERSION@")
set(QUIRC_INCLUDE_DIRS "${_IMPORT_PREFIX}/include")
set(QUIRC_LIBRARIES "${_QUIRC_LIB}")
set(quirc_FOUND TRUE)

unset(_IMPORT_PREFIX)
unset(_QUIRC_LIB)
