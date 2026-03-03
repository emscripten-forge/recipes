# zlibConfig.cmake.in
# CMake configuration file template for zlib

include(CMakeFindDependencyMacro)

# Compute the installation prefix relative to this file
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)

# Create imported target
if(NOT TARGET ZLIB::ZLIB)
    add_library(ZLIB::ZLIB STATIC IMPORTED)
    
    # Set the location of the library
    set_target_properties(ZLIB::ZLIB PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libz.a"
        INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
    )
endif()

# Legacy variables for compatibility
set(ZLIB_FOUND TRUE)
set(ZLIB_INCLUDE_DIRS "${_IMPORT_PREFIX}/include")
set(ZLIB_LIBRARIES "${_IMPORT_PREFIX}/lib/libz.a")
set(ZLIB_VERSION "@ZLIB_VERSION@")

# Mark as found
set(zlib_FOUND TRUE)

# Cleanup
unset(_IMPORT_PREFIX)
