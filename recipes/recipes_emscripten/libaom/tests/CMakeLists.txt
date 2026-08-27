cmake_minimum_required(VERSION 3.18)
project(test_aom C)

find_package(AOM REQUIRED)

add_executable(test_aom test_aom.c)
target_compile_options(test_aom PRIVATE
    -sSUPPORT_LONGJMP=wasm
)
target_link_libraries(test_aom PRIVATE
    AOM::aom
)
target_link_options(test_aom PRIVATE
    -sSUPPORT_LONGJMP=wasm
    -sMAIN_MODULE=1
    -sEXIT_RUNTIME=1
    -sNO_INVOKE_RUN=0
    -sNODEJS_CATCH_EXIT=0
    -sNODEJS_CATCH_REJECTION=0
)

set_target_properties(test_aom PROPERTIES
    SUFFIX ".js"
)
