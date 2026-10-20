cmake_minimum_required(VERSION 3.19)
project(tokenizers_cpp_test CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(tokenizers-cpp REQUIRED)

add_executable(test_tokenizers test_tokenizers.cpp)
target_link_libraries(test_tokenizers PRIVATE tokenizers_cpp)

if(EMSCRIPTEN)
    target_link_options(test_tokenizers PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
        "LINKER:--allow-multiple-definition"
        -sERROR_ON_UNDEFINED_SYMBOLS=0
    )

    # Embed test models into the WASM binary so LoadBytesFromFile works.
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/dist")
        file(GLOB _model_files "${CMAKE_CURRENT_SOURCE_DIR}/dist/*")
        foreach(_f ${_model_files})
            get_filename_component(_name "${_f}" NAME)
            target_link_options(test_tokenizers PRIVATE
                "--preload-file=${_f}@dist/${_name}"
            )
        endforeach()
    endif()
endif()
