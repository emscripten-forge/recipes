add_library(fxdiv INTERFACE)
target_include_directories(fxdiv INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
add_library(FXdiv ALIAS fxdiv)
