cmake_minimum_required(VERSION 3.22)
project(cgal_smoke_test CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(CGAL REQUIRED)

add_executable(test_cgal test_cgal.cpp)
target_link_libraries(test_cgal PRIVATE CGAL::CGAL)
