cmake_minimum_required(VERSION 3.18)
project(test_opencv CXX)

# Use find_package only to get include dirs and verify OpenCV exists,
# but link manually to avoid SIDE_MODULE=1 leaking from OpenCV's targets.
find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs)

add_executable(test_opencv test_opencv.cpp)
target_include_directories(test_opencv PRIVATE ${OpenCV_INCLUDE_DIRS})
target_compile_options(test_opencv PRIVATE
    -sSUPPORT_LONGJMP=wasm
    -fwasm-exceptions
)
target_link_libraries(test_opencv PRIVATE
    ${CMAKE_PREFIX_PATH}/lib/libopencv_imgcodecs.a
    ${CMAKE_PREFIX_PATH}/lib/libopencv_imgproc.a
    ${CMAKE_PREFIX_PATH}/lib/libopencv_core.a
    ${CMAKE_PREFIX_PATH}/lib/libjpeg.a
    ${CMAKE_PREFIX_PATH}/lib/libwebp.a
    ${CMAKE_PREFIX_PATH}/lib/libsharpyuv.a
    ${CMAKE_PREFIX_PATH}/lib/libwebpmux.a
    ${CMAKE_PREFIX_PATH}/lib/libwebpdemux.a
    ${CMAKE_PREFIX_PATH}/lib/libpng.a
    ${CMAKE_PREFIX_PATH}/lib/libtiff.a
    ${CMAKE_PREFIX_PATH}/lib/libz.a
    ${CMAKE_PREFIX_PATH}/lib/libopenjp2.a
)
target_link_options(test_opencv PRIVATE
    -sSUPPORT_LONGJMP=wasm
    -fwasm-exceptions
    -sMAIN_MODULE=1
    -sEXIT_RUNTIME=1
    -sNO_INVOKE_RUN=0
    -sNODEJS_CATCH_EXIT=0
    -sNODEJS_CATCH_REJECTION=0
    "SHELL:--preload-file ${CMAKE_CURRENT_SOURCE_DIR}/logo.png@/logo.png"
)

set_target_properties(test_opencv PROPERTIES
    SUFFIX ".js"
)
