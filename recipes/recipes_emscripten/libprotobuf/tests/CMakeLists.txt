cmake_minimum_required(VERSION 3.16)
project(test_protobuf_cpp CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(protobuf CONFIG REQUIRED)

add_executable(test_protobuf_cpp test_protobuf.cpp)
target_link_libraries(test_protobuf_cpp protobuf::libprotobuf)
