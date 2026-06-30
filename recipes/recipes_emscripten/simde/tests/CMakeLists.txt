cmake_minimum_required(VERSION 3.22)
project(test_simde C)

find_package(simde CONFIG REQUIRED)

add_executable(test_simde test_simde.c)
target_link_libraries(test_simde PRIVATE simde::simde)
