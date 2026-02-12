cmake_minimum_required(VERSION 3.15)
project(zlib_tests C)

# Find zlib using the config file
find_package(zlib REQUIRED CONFIG)

# Create test executable
add_executable(test_zlib test_zlib.c)

# Link against zlib
target_link_libraries(test_zlib PRIVATE ZLIB::ZLIB)

# Set output directory
set_target_properties(test_zlib PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
