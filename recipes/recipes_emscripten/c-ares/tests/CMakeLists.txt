cmake_minimum_required(VERSION 3.10)
project(c-ares-test C)

set(CMAKE_C_STANDARD 11)

find_package(c-ares REQUIRED CONFIG)

add_executable(test_cares test_cares.c)
target_link_libraries(test_cares PRIVATE c-ares::cares)
target_include_directories(test_cares PRIVATE ${CMAKE_PREFIX_PATH}/include)
