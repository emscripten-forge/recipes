cmake_minimum_required(VERSION 3.20)
project(ort_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(onnxruntime-wasm REQUIRED)

add_executable(test_ort test_ort.cpp)

target_link_libraries(test_ort PRIVATE onnxruntime::onnxruntime_webassembly)

# Additional link options specific to the Node.js test environment
if(EMSCRIPTEN)
    target_link_options(test_ort PRIVATE
        -sENVIRONMENT=node
        -sNODERAWFS=1   # Allow direct host-filesystem access from Node.js
    )
endif()
