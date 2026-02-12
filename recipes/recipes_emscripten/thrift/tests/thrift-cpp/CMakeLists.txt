cmake_minimum_required(VERSION 3.14)
project(test_thrift_cpp)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(thrift REQUIRED CONFIG)

add_executable(test_thrift-cpp test_thrift.cpp)
target_link_libraries(test_thrift-cpp thrift::thrift)
