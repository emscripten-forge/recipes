cmake_minimum_required(VERSION 3.22)
project(test_ffmpeg C)
set(CMAKE_C_STANDARD 99)

find_package(FFmpeg CONFIG REQUIRED)

add_executable(test_ffmpeg test_ffmpeg.c)

target_link_libraries(test_ffmpeg
  FFmpeg::avformat
  FFmpeg::swscale
  FFmpeg::swresample
)

# Emscripten: produce .js output
set_target_properties(test_ffmpeg PROPERTIES
  SUFFIX ".js"
)
