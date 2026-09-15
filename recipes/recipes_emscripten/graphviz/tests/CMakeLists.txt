cmake_minimum_required(VERSION 3.21)
project(test_graphviz C)

find_package(Graphviz REQUIRED CONFIG)

add_executable(test_graphviz test_graphviz.c)
target_link_libraries(test_graphviz PRIVATE Graphviz::graphviz)

if(EMSCRIPTEN)
    target_link_options(test_graphviz PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
        -sEXIT_RUNTIME=1
    )
endif()
