cmake_minimum_required(VERSION 3.20)
project(arrow_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Arrow REQUIRED)

add_executable(test_arrow test_arrow.cpp)
target_link_libraries(test_arrow PRIVATE Arrow::arrow_static)
