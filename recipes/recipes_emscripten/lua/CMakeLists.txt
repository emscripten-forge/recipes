# Credit to https://github.com/walterschell/Lua/blob/master/lua-5.3.3/CMakeLists.txt
# The version is inspired by the above link.
cmake_minimum_required(VERSION 3.1)
project(lua C)

include_directories(src)
set(LUA_LIB_SRCS
    src/lapi.c
    src/lcode.c
    src/lctype.c
    src/ldebug.c
    src/ldo.c
    src/ldump.c
    src/lfunc.c
    src/lgc.c
    src/llex.c
    src/lmem.c
    src/lobject.c
    src/lopcodes.c
    src/lparser.c
    src/lstate.c
    src/lstring.c
    src/ltable.c
    src/ltm.c
    src/lundump.c
    src/lvm.c
    src/lzio.c
    src/lauxlib.c
    src/lbaselib.c
    src/lcorolib.c
    src/ldblib.c
    src/liolib.c
    src/lmathlib.c
    src/loslib.c
    src/lstrlib.c
    src/ltablib.c
    src/lutf8lib.c
    src/loadlib.c
    src/linit.c)

add_library(liblua ${LUA_LIB_SRCS})

# fpic
set_target_properties(liblua PROPERTIES POSITION_INDEPENDENT_CODE ON)

set_target_properties(liblua PROPERTIES OUTPUT_NAME "lua")
if(BUILD_SHARED_LIBS)
  target_compile_definitions(liblua PRIVATE LUA_BUILD_AS_DLL)
endif()




add_executable(lua src/lua.c ${LUA_LIB_SRCS})
target_link_libraries(lua)
add_executable(luac src/luac.c ${LUA_LIB_SRCS})
target_link_libraries(luac)


set(lua_binaries lua luac)

foreach(lua_binary ${lua_binaries})
  # set target compile options
  target_compile_definitions(${lua_binary}
      PUBLIC "SHELL: -s FORCE_FILESYSTEM"
      PUBLIC "SHELL: -s ALLOW_MEMORY_GROWTH=1"
      PUBLIC "SHELL: -s EXIT_RUNTIME=1"
      PUBLIC "SHELL: -s EXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY"
      PUBLIC "SHELL: -s MODULARIZE=1"
  )
  # set target link options
  target_link_options(${lua_binary}
      PUBLIC "SHELL: -s FORCE_FILESYSTEM"
      PUBLIC "SHELL: -s ALLOW_MEMORY_GROWTH=1"
      PUBLIC "SHELL: -s EXIT_RUNTIME=1"
      PUBLIC "SHELL: -s EXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY"
      PUBLIC "SHELL: -s MODULARIZE=1"
  )
endforeach()





install(TARGETS liblua
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin)

install(TARGETS lua luac DESTINATION bin)



install(FILES
        "$<TARGET_FILE_DIR:lua>/lua.wasm"
        DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
install(FILES
        "$<TARGET_FILE_DIR:luac>/luac.wasm"
        DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)


set(LUA_PUBLIC_INCLUDES
    src/lauxlib.h
    src/lua.h
    src/lua.hpp
    src/luaconf.h
    src/lualib.h)

install(FILES ${LUA_PUBLIC_INCLUDES}
        DESTINATION include)
