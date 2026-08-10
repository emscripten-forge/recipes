cmake_minimum_required(VERSION 3.16)
project(test_antlr4_runtime CXX)
set(CMAKE_CXX_STANDARD 17)

find_path(ANTLR4_INCLUDE_DIR antlr4-runtime.h
    PATHS "${PREFIX}/include/antlr4-runtime"
    NO_DEFAULT_PATH)

find_library(ANTLR4_LIBRARY antlr4-runtime
    PATHS "${PREFIX}/lib"
    NO_DEFAULT_PATH)

if(NOT ANTLR4_INCLUDE_DIR OR NOT ANTLR4_LIBRARY)
    message(FATAL_ERROR "Could not find antlr4-runtime library or headers")
endif()

add_executable(test_antlr4_runtime test_antlr4.cpp)
target_include_directories(test_antlr4_runtime PRIVATE
    "${PREFIX}/include"
    "${ANTLR4_INCLUDE_DIR}")
target_link_libraries(test_antlr4_runtime PRIVATE ${ANTLR4_LIBRARY})
