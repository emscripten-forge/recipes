cmake_minimum_required(VERSION 3.16)
project(lua C)
set(LUA_SRC
  src/lapi.c src/lauxlib.c src/lbaselib.c src/lcode.c src/lcorolib.c src/lctype.c
  src/ldblib.c src/ldebug.c src/ldo.c src/ldump.c src/lfunc.c src/lgc.c src/linit.c
  src/liolib.c src/llex.c src/lmathlib.c src/lmem.c src/loadlib.c src/lobject.c
  src/lopcodes.c src/loslib.c src/lparser.c src/lstate.c src/lstring.c src/lstrlib.c
  src/ltable.c src/ltablib.c src/ltm.c src/lundump.c src/lutf8lib.c src/lvm.c src/lzio.c)
add_library(lua STATIC ${LUA_SRC})
target_include_directories(lua PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src> $<INSTALL_INTERFACE:include>)
target_compile_definitions(lua PRIVATE LUA_USE_POSIX)
set_target_properties(lua PROPERTIES OUTPUT_NAME lua)
install(TARGETS lua ARCHIVE DESTINATION lib)
install(FILES src/lua.h src/luaconf.h src/lauxlib.h src/lualib.h DESTINATION include)
