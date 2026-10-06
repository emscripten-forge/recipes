cmake_minimum_required(VERSION 3.15)
project(cpuinfo_tests)

set(CMAKE_C_STANDARD 11)

find_package(cpuinfo REQUIRED CONFIG)

add_executable(test_cpuinfo test_cpuinfo.c)
target_link_libraries(test_cpuinfo PRIVATE cpuinfo::cpuinfo)
