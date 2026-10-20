cmake_minimum_required(VERSION 3.18)
project(test_gflags CXX)

find_package(gflags REQUIRED)

add_executable(test_gflags test_gflags.cpp)
target_link_libraries(test_gflags PRIVATE gflags::gflags)