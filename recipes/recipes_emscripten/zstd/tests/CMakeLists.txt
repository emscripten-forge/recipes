cmake_minimum_required(VERSION 3.15)
project(zstd_tests CXX)

set(CMAKE_CXX_STANDARD 17)

# Find zstd
find_package(zstd REQUIRED CONFIG)

# Test executable that uses zstd
add_executable(test_zstd test_zstd.cpp)
target_link_libraries(test_zstd PRIVATE zstd::libzstd_static)
