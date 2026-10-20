cmake_minimum_required(VERSION 3.16)
project(test_sentencepiece_cpp CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(sentencepiece REQUIRED)

add_executable(test_sentencepiece_cpp test_sentencepiece.cpp)
target_link_libraries(test_sentencepiece_cpp PRIVATE
    sentencepiece::sentencepiece
)
