cmake_minimum_required(VERSION 3.15)
project(minizip_tests C)

# Create test executable
add_executable(test_minizip test_minizip.c)

# Use explicit paths since minizip-ng config may not be in the test env
target_include_directories(test_minizip PRIVATE ${CMAKE_PREFIX_PATH}/include)
target_link_directories(test_minizip PRIVATE ${CMAKE_PREFIX_PATH}/lib)
target_link_libraries(test_minizip PRIVATE minizip)

# Set output directory
set_target_properties(test_minizip PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
