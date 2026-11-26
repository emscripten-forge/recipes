cmake_minimum_required(VERSION 3.18)
project(test_libgdal C)

set(GDAL_PREFIX "$ENV{PREFIX}")
set(GDAL_LIBRARY "${GDAL_PREFIX}/lib/libgdal.so")
set(GDAL_INCLUDE_DIR "${GDAL_PREFIX}/include")

if(NOT EXISTS "${GDAL_LIBRARY}")
    message(FATAL_ERROR "GDAL library not found at ${GDAL_LIBRARY}")
endif()
if(NOT EXISTS "${GDAL_INCLUDE_DIR}/gdal.h")
    message(FATAL_ERROR "gdal.h not found at ${GDAL_INCLUDE_DIR}")
endif()

add_executable(test_libgdal test_libgdal.c)
target_include_directories(test_libgdal PRIVATE ${GDAL_INCLUDE_DIR})
target_link_directories(test_libgdal PRIVATE ${GDAL_PREFIX}/lib)
target_link_libraries(test_libgdal PRIVATE ${GDAL_LIBRARY})
target_compile_options(test_libgdal PRIVATE
    -fwasm-exceptions
    -sSUPPORT_LONGJMP=wasm
)
target_link_options(test_libgdal PRIVATE
    -fwasm-exceptions
    -sSUPPORT_LONGJMP=wasm
    -L${GDAL_PREFIX}/lib
    -sMAIN_MODULE=1
    -sWASM_BIGINT
    -sEXIT_RUNTIME=1
    -sERROR_ON_UNDEFINED_SYMBOLS=0
    -sFORCE_FILESYSTEM=1
    -lnodefs.js
    -sNODEJS_CATCH_EXIT=0
    -sNODEJS_CATCH_REJECTION=0
    --pre-js ${CMAKE_CURRENT_SOURCE_DIR}/pre.js
)
set_target_properties(test_libgdal PROPERTIES SUFFIX ".js")
