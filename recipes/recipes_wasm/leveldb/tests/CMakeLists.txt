cmake_minimum_required(VERSION 3.9)
project(test_leveldb)

find_package(leveldb REQUIRED)

add_executable(test_leveldb test_leveldb.cpp)
target_link_libraries(test_leveldb leveldb::leveldb)
set_target_properties(test_leveldb PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
