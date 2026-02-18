cmake_minimum_required(VERSION 3.15)
project(lz4_tests)

set(CMAKE_CXX_STANDARD 11)

# Find lz4
find_package(lz4 REQUIRED CONFIG)

# Create test executable
add_executable(test_lz4 test_lz4.cpp)
target_link_libraries(test_lz4 PRIVATE lz4::lz4)
