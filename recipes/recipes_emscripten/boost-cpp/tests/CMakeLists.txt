cmake_minimum_required(VERSION 3.20)
project(boost_module_test CXX)

if(NOT DEFINED MOD)
    message(FATAL_ERROR "pass -DMOD=<base>, e.g. -DMOD=accumulators")
endif()

find_package(boost_${MOD} CONFIG REQUIRED)

add_executable(test_${MOD} test_${MOD}.cpp)
target_link_libraries(test_${MOD} PRIVATE Boost::${MOD})

target_compile_options(test_${MOD} PRIVATE
    -fwasm-exceptions -DBOOST_WAVE_SUPPORT_THREADING=0)
target_link_options(test_${MOD} PRIVATE -fwasm-exceptions)

if(EMSCRIPTEN)
    target_link_options(test_${MOD} PRIVATE
        "-sALLOW_MEMORY_GROWTH=1" "-sINITIAL_MEMORY=64MB"
        "-sMAXIMUM_MEMORY=512MB" "-sFORCE_FILESYSTEM=1")
endif()
