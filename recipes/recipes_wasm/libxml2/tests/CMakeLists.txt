cmake_minimum_required(VERSION 3.15)
project(libxml2_tests C)

find_package(libxml2 REQUIRED CONFIG)
find_package(ZLIB REQUIRED CONFIG)

add_executable(test_libxml2 test_libxml2.c)
# Link zlib explicitly for gzopen/gzwrite/gzclose — the test writes its own
# .xml.gz fixture in-process so it doesn't depend on host gzip.
target_link_libraries(test_libxml2 PRIVATE
    LibXml2::LibXml2
    ZLIB::ZLIBSTATIC
)

set_target_properties(test_libxml2 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
