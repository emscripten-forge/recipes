cmake_minimum_required(VERSION 3.20)
project(test_lld_static LANGUAGES C CXX)

find_package(LLD $ENV{PKG_VERSION} EXACT REQUIRED CONFIG)
foreach(component lldCommon lldWasm)
  if(NOT TARGET ${component})
    message(FATAL_ERROR "Missing imported target: ${component}")
  endif()
endforeach()
