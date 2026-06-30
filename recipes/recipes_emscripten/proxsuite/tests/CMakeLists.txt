cmake_minimum_required(VERSION 3.22)
project(test_proxsuite CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(proxsuite CONFIG REQUIRED)

add_executable(test_proxsuite test_proxsuite.cpp)
target_link_libraries(test_proxsuite PRIVATE proxsuite::proxsuite)

target_link_options(test_proxsuite PRIVATE)
