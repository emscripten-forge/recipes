cmake_minimum_required(VERSION 3.20)
project(dataset_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Arrow REQUIRED)
find_package(ArrowDataset REQUIRED)

add_executable(test_dataset test_dataset.cpp)
target_link_libraries(test_dataset PRIVATE 
    ArrowDataset::arrow_dataset_static 
    Arrow::arrow_static)
