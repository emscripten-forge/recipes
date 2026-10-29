cmake_minimum_required(VERSION 3.20)
project(compute_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Arrow REQUIRED)
find_package(ArrowCompute REQUIRED)

add_executable(test_compute test_compute.cpp)
target_link_libraries(test_compute PRIVATE ArrowCompute::arrow_compute_static Arrow::arrow_static)
