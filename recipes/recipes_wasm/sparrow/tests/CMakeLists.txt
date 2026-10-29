cmake_minimum_required(VERSION 3.20)
project(sparrow_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(sparrow REQUIRED)

add_executable(test_simple test_simple.cpp)
target_link_libraries(test_simple PRIVATE sparrow::sparrow)
