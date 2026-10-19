cmake_minimum_required(VERSION 3.15)
project(stb_test C)

set(CMAKE_C_STANDARD 99)

find_path(STB_INCLUDE_DIR stb_image.h REQUIRED)

add_executable(test_stb test_stb.c)
target_include_directories(test_stb PRIVATE ${STB_INCLUDE_DIR})
