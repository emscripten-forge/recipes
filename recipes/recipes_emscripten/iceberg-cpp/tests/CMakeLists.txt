cmake_minimum_required(VERSION 3.25)
project(iceberg_cpp_tests CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(iceberg REQUIRED CONFIG)

add_executable(test_iceberg test_iceberg.cpp)
target_link_libraries(test_iceberg PRIVATE iceberg::iceberg_static)

set_target_properties(test_iceberg PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)