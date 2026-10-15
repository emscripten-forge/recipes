# stb CMake config file
#
# find_package(stb) provides the target stb::headers.
# Usage:
#   find_package(stb REQUIRED)
#   target_link_libraries(my_target PRIVATE stb::headers)
#
# Then in your code:
#   #define STB_IMAGE_IMPLEMENTATION
#   #include "stb_image.h"

include("${CMAKE_CURRENT_LIST_DIR}/stbTargets.cmake")
