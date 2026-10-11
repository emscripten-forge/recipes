cmake_minimum_required(VERSION 3.16)
project(test_onetbb CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(TBB CONFIG REQUIRED)

# Test TBB threading library
add_executable(test_onetbb test_onetbb.cpp)
target_link_libraries(test_onetbb TBB::tbb)

# Test TBB malloc library (needed by oneDAL)
add_executable(test_onetbb_malloc test_onetbb_malloc.cpp)
target_link_libraries(test_onetbb_malloc TBB::tbbmalloc)
