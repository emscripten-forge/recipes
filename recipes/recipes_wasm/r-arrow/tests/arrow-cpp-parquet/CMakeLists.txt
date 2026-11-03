cmake_minimum_required(VERSION 3.20)
project(parquet_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# find_package(Arrow REQUIRED)
find_package(thrift REQUIRED)
find_package(Parquet REQUIRED)

add_executable(test_parquet test_parquet.cpp)
target_link_libraries(test_parquet PRIVATE Parquet::parquet_static)
