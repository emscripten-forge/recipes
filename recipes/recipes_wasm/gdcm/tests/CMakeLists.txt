cmake_minimum_required(VERSION 3.16)
project(test_gdcm CXX)
set(CMAKE_CXX_STANDARD 11)

find_package(GDCM CONFIG REQUIRED)

add_executable(test_gdcm test_gdcm.cpp)
target_link_libraries(test_gdcm PRIVATE
  gdcmCommon
  gdcmDSED
  gdcmIOD
  gdcmMSFF
  gdcmDICT
)
