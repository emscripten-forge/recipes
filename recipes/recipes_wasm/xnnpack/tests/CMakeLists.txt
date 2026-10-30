cmake_minimum_required(VERSION 3.16)
project(test_xnnpack CXX)
set(CMAKE_CXX_STANDARD 20)

find_package(XNNPACK CONFIG REQUIRED)

add_library(test_xnnpack SHARED test_xnnpack.cpp)
target_link_libraries(test_xnnpack PRIVATE XNNPACK::xnnpack XNNPACK::xnnpack-microkernels-prod)
