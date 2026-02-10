cmake_minimum_required(VERSION 3.20)
project(acero_test CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Arrow REQUIRED)
find_package(ArrowAcero REQUIRED)

add_executable(test_acero test_acero.cpp)
target_link_libraries(test_acero PRIVATE ArrowAcero::arrow_acero_static Arrow::arrow_static)
