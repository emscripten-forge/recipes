cmake_minimum_required(VERSION 3.16)
project(test_onetbb CXX)
set(CMAKE_CXX_STANDARD 17)

# pthreads are required to match libtbb.a (compiled with -pthread).
# -sPROXY_TO_PTHREAD is recommended by oneTBB WASM docs to prevent
# deadlocks from nested Web Worker scheduling.
# These flags must be set BEFORE find_package / add_executable so they
# affect both compilation and linking.
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread -sPROXY_TO_PTHREAD")

find_package(TBB CONFIG REQUIRED)

# Test TBB threading library
add_executable(test_onetbb test_onetbb.cpp)
target_link_libraries(test_onetbb TBB::tbb)

# Test TBB malloc library (needed by oneDAL)
add_executable(test_onetbb_malloc test_onetbb_malloc.cpp)
target_link_libraries(test_onetbb_malloc TBB::tbbmalloc)
