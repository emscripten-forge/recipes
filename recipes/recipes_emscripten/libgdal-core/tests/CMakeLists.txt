cmake_minimum_required(VERSION 3.18)
project(test_libgdal C)

find_library(GDAL_LIBRARY gdal
    PATHS "${CMAKE_PREFIX_PATH}/lib" "$ENV{PREFIX}/lib"
    NO_DEFAULT_PATH)
find_path(GDAL_INCLUDE_DIR gdal.h
    PATHS "${CMAKE_PREFIX_PATH}/include" "$ENV{PREFIX}/include"
    NO_DEFAULT_PATH)

if(NOT GDAL_LIBRARY OR NOT GDAL_INCLUDE_DIR)
    message(FATAL_ERROR "Could not find GDAL library or headers")
endif()

add_executable(test_libgdal test_libgdal.c)
target_include_directories(test_libgdal PRIVATE ${GDAL_INCLUDE_DIR})
target_link_libraries(test_libgdal PRIVATE ${GDAL_LIBRARY})
target_link_options(test_libgdal PRIVATE
    -sMAIN_MODULE=1
    -sWASM_BIGINT
    -sEXIT_RUNTIME=1
    -sNODEJS_CATCH_EXIT=0
    -sNODEJS_CATCH_REJECTION=0
)
set_target_properties(test_libgdal PROPERTIES SUFFIX ".js")
