cmake_minimum_required(VERSION 3.15)
project(miniaudio_test C)

set(CMAKE_C_STANDARD 99)

find_package(miniaudio REQUIRED)

add_executable(test_miniaudio test_miniaudio.c)
target_link_libraries(test_miniaudio PRIVATE miniaudio::miniaudio)

set_target_properties(test_miniaudio PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
