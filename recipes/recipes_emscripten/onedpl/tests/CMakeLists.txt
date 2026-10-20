cmake_minimum_required(VERSION 3.16)
project(test_onedpl CXX)
set(CMAKE_CXX_STANDARD 17)

# oneDPL with TBB backend requires pthreads
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread")

find_package(TBB CONFIG REQUIRED)
find_package(oneDPL CONFIG REQUIRED)

add_executable(test_onedpl test_onedpl.cpp)
target_link_libraries(test_onedpl oneDPL TBB::tbb)
