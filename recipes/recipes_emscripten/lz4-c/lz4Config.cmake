# lz4Config.cmake
# CMake configuration file for lz4-c

include(CMakeFindDependencyMacro)

# Compute the installation prefix relative to this file
# Assumes config is installed at: ${PREFIX}/lib/cmake/lz4/lz4Config.cmake
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)

# Verify library exists
set(_LZ4_LIB "${_IMPORT_PREFIX}/lib/liblz4.a")
if(NOT EXISTS "${_LZ4_LIB}")
    set(lz4_FOUND FALSE)
    set(LZ4_FOUND FALSE)
    if(lz4_FIND_REQUIRED)
        message(FATAL_ERROR "lz4 library not found at ${_LZ4_LIB}")
    elseif(NOT lz4_FIND_QUIETLY)
        message(WARNING "lz4 library not found at ${_LZ4_LIB}")
    endif()
    return()
endif()

# Create imported target
if(NOT TARGET lz4::lz4)
    add_library(lz4::lz4 STATIC IMPORTED)
    
    set_target_properties(lz4::lz4 PROPERTIES
        IMPORTED_LOCATION "${_LZ4_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
    )
endif()

# Legacy variables for compatibility
set(LZ4_FOUND TRUE)
set(LZ4_INCLUDE_DIRS "${_IMPORT_PREFIX}/include")
set(LZ4_LIBRARIES "${_LZ4_LIB}")
set(LZ4_VERSION "@VERSION@")

# Mark as found
set(lz4_FOUND TRUE)

# Cleanup
unset(_IMPORT_PREFIX)
unset(_LZ4_LIB)
