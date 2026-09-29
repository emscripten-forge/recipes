cmake_minimum_required(VERSION 3.15)
project(libxml2_tests C)

find_package(libxml2 REQUIRED CONFIG)

add_executable(test_libxml2 test_libxml2.c)
target_link_libraries(test_libxml2 PRIVATE LibXml2::LibXml2)

set_target_properties(test_libxml2 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
