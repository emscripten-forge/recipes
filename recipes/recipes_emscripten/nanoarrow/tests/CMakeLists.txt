cmake_minimum_required(VERSION 3.14)
project(nanoarrow_tests C)

find_package(nanoarrow REQUIRED CONFIG)

add_executable(test_nanoarrow test_nanoarrow.c)
target_link_libraries(test_nanoarrow PRIVATE nanoarrow::nanoarrow_static)

set_target_properties(test_nanoarrow PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)