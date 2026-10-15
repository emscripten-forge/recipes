cmake_minimum_required(VERSION 3.20)
project(ggml_tests CXX)

set(CMAKE_CXX_STANDARD 20)

find_package(ggml REQUIRED)
add_executable(test_ggml test_ggml.cpp)
target_link_libraries(test_ggml PRIVATE ggml::ggml)
set_target_properties(test_ggml PROPERTIES SUFFIX ".js")
