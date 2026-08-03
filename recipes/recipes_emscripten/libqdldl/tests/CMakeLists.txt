cmake_minimum_required(VERSION 3.18)
project(test_qdldl C)

find_package(qdldl REQUIRED)

add_executable(test_qdldl test_qdldl.c)
target_link_libraries(test_qdldl PRIVATE qdldl::qdldlstatic)
