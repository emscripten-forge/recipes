cmake_minimum_required(VERSION 3.25)
project(executorch_cpp_tests CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(executorch REQUIRED CONFIG)

add_executable(test_executorch test_executorch.cpp)
target_link_libraries(test_executorch PRIVATE executorch extension_module extension_tensor)

set_target_properties(test_executorch PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)