cmake_minimum_required(VERSION 3.18)
project(test_opencv CXX)

find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs)

add_executable(test_opencv test_opencv.cpp)
target_compile_options(test_opencv PRIVATE
    -sSUPPORT_LONGJMP=wasm
    -fwasm-exceptions
)
target_link_libraries(test_opencv PRIVATE
    opencv_imgcodecs
)
target_link_options(test_opencv PRIVATE
    -sSUPPORT_LONGJMP=wasm
    -fwasm-exceptions
    -sMAIN_MODULE=1
    -sEXIT_RUNTIME=1
    -sNO_INVOKE_RUN=0
    -sNODEJS_CATCH_EXIT=0
    -sNODEJS_CATCH_REJECTION=0
)

set_target_properties(test_opencv PROPERTIES
    SUFFIX ".js"
)
