cmake_minimum_required(VERSION 3.15)
project(openssl_tests CXX)

set(CMAKE_CXX_STANDARD 17)

# Find OpenSSL using CONFIG mode to use our OpenSSLConfig.cmake
find_package(OpenSSL REQUIRED CONFIG)

# Test executable that uses OpenSSL
add_executable(test_openssl test_openssl.cpp)
target_link_libraries(test_openssl PRIVATE OpenSSL::SSL OpenSSL::Crypto)
