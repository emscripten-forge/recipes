cmake_minimum_required(VERSION 3.25)
project(executorch_cpp_tests CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(executorch REQUIRED CONFIG)

add_executable(test_executorch test_executorch.cpp)
target_link_libraries(test_executorch PRIVATE executorch extension_module extension_tensor)

add_executable(test_model_metadata test_model_metadata.cpp)
target_link_libraries(
    test_model_metadata
    PRIVATE executorch extension_data_loader extension_module extension_tensor
)
target_link_options(test_model_metadata PRIVATE "SHELL:-sNODERAWFS=1")

set_target_properties(test_executorch PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

set_target_properties(test_model_metadata PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)