# stb CMake targets file
#
# Defines the header-only imported target stb::headers.
# Defines the static library target stb::vorbis.

if(NOT TARGET stb::headers)
    add_library(stb::headers INTERFACE IMPORTED)
    set_target_properties(stb::headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
    )
endif()

if(NOT TARGET stb::vorbis)
    add_library(stb::vorbis STATIC IMPORTED)
    set_target_properties(stb::vorbis PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libstb_vorbis.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
    )
endif()
