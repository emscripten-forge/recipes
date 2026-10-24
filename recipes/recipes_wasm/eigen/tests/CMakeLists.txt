cmake_minimum_required(VERSION 3.20)
project(eigen_lapack_test CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Eigen3 REQUIRED CONFIG)

find_library(OPENBLAS_LIBRARY NAMES openblas REQUIRED)

add_executable(test_eigen_lapack test_eigen_lapack.cc)

# EIGEN_USE_LAPACKE routes Eigen's dense decompositions through LAPACKE_*.
target_compile_definitions(test_eigen_lapack PRIVATE EIGEN_USE_LAPACKE)

target_compile_options(test_eigen_lapack PRIVATE -fwasm-exceptions -msimd128)

target_link_libraries(test_eigen_lapack PRIVATE
    Eigen3::Eigen
    ${OPENBLAS_LIBRARY}
)

if(EMSCRIPTEN)
    target_link_options(test_eigen_lapack PRIVATE
        -sMAIN_MODULE=2
        -fwasm-exceptions -sSUPPORT_LONGJMP=wasm -msimd128
        -sALLOW_MEMORY_GROWTH=1
        -sSTACK_SIZE=8MB
        -sENVIRONMENT=node
        -sEXIT_RUNTIME=1
    )
endif()
