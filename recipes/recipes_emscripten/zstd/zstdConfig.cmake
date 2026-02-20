# zstd CMake config for conda environment

# Create imported target for libzstd
add_library(zstd::libzstd_static STATIC IMPORTED)
set_target_properties(zstd::libzstd_static PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libzstd.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
)

# Create an alias that's compatible with find_package(zstd)
add_library(zstd::libzstd ALIAS zstd::libzstd_static)

# Set version information
set(zstd_VERSION "@VERSION@")
set(ZSTD_VERSION "@VERSION@")
set(zstd_FOUND TRUE)
set(ZSTD_FOUND TRUE)

# Legacy variables for compatibility
set(ZSTD_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../include")
set(ZSTD_LIBRARY "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libzstd.a")
set(ZSTD_LIBRARIES "${ZSTD_LIBRARY}")
set(ZSTD_INCLUDE_DIRS "${ZSTD_INCLUDE_DIR}")
