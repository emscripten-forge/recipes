cmake_minimum_required(VERSION 3.16)
project(glfw_test CXX)

find_package(glfw3 REQUIRED CONFIG)

add_executable(test_glfw test_glfw.cpp)
target_link_libraries(test_glfw PRIVATE glfw)
set_target_properties(test_glfw PROPERTIES SUFFIX ".js")
