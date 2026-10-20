# Minja CMake config file
#
# This file provides the imported target "minja" for downstream consumption.
# Usage: find_package(minja REQUIRED)
#         target_link_libraries(my_target PRIVATE minja)

include(CMakeFindDependencyMacro)
find_dependency(nlohmann_json REQUIRED)

include("${CMAKE_CURRENT_LIST_DIR}/minjaTargets.cmake")
