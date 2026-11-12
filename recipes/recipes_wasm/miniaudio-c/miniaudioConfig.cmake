# miniaudioConfig.cmake
# CMake configuration file for miniaudio

include(CMakeFindDependencyMacro)

# Compute the installation prefix relative to this file
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)

# Create imported target
if(NOT TARGET miniaudio::miniaudio)
    add_library(miniaudio::miniaudio STATIC IMPORTED)

    set_target_properties(miniaudio::miniaudio PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libminiaudio.a"
        INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/miniaudio"
    )
endif()
