# Minimal zstd CMake config for conda environment

add_library(zstd_static STATIC IMPORTED)
set_target_properties(zstd_static PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libzstd.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
)

# Create the aliases that sparrow-ipc expects
add_library(zstd::libzstd ALIAS zstd_static)
add_library(zstd::libzstd_static ALIAS zstd_static)

set(zstd_FOUND TRUE)
