# Minja CMake targets file
#
# Generated targets file for the minja header-only library.

if(NOT TARGET minja)
    add_library(minja INTERFACE IMPORTED)
    set_target_properties(minja PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
        INTERFACE_LINK_LIBRARIES "nlohmann_json::nlohmann_json"
    )
endif()
