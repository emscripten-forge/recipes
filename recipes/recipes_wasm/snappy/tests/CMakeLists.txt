cmake_minimum_required(VERSION 3.15)
project(snappy_tests)

set(CMAKE_CXX_STANDARD 11)

# Find snappy
find_package(Snappy REQUIRED CONFIG)

# Create test executable
add_executable(test_snappy test_snappy.cpp)
target_link_libraries(test_snappy PRIVATE Snappy::snappy)
