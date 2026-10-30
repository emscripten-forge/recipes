cmake_minimum_required(VERSION 3.20)
project(test_itk CXX)

find_package(ITK REQUIRED COMPONENTS ITKCommon ITKIOImageBase ITKIOPNG ITKIOGDCM ITKIOHDF5)
include(${ITK_USE_FILE})

add_executable(test_itk test_itk.cxx)
target_link_libraries(test_itk PRIVATE ${ITK_LIBRARIES})

if(EMSCRIPTEN)
    target_compile_options(test_itk PRIVATE -fwasm-exceptions -msimd128)
    target_link_options(test_itk PRIVATE
        -fwasm-exceptions -sSUPPORT_LONGJMP=wasm -msimd128
        -sNODERAWFS=1
        -sALLOW_MEMORY_GROWTH=1
        -sSTACK_SIZE=8MB
        -sENVIRONMENT=node
        -sEXIT_RUNTIME=1
    )
endif()
