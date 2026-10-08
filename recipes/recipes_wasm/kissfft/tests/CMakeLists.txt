cmake_minimum_required(VERSION 3.10)
project(kissfft_tests C)

find_package(kissfft REQUIRED)

add_executable(test_kissfft test_kissfft.c)
target_link_libraries(test_kissfft PRIVATE kissfft::kissfft-float)
