cmake_minimum_required(VERSION 3.15)
project(fxdiv_test C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

find_path(FXDIV_INCLUDE_DIR fxdiv.h REQUIRED)

add_executable(test_fxdiv test_fxdiv.c)
target_include_directories(test_fxdiv PRIVATE ${FXDIV_INCLUDE_DIR})
