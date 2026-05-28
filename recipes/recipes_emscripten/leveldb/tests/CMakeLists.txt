cmake_minimum_required(VERSION 3.9)
project(test_leveldb)

add_executable(test_leveldb test_leveldb.cpp)
target_include_directories(test_leveldb PRIVATE $ENV{PREFIX}/include)
target_link_libraries(test_leveldb $ENV{PREFIX}/lib/libleveldb.a)
set_target_properties(test_leveldb PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
