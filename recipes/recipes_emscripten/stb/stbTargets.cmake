# stb CMake targets file
#
# Defines the header-only imported target stb::headers.

if(NOT TARGET stb::headers)
    add_library(stb::headers INTERFACE IMPORTED)
    set_target_properties(stb::headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
    )
endif()
