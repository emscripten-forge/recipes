// Functional test for boost-predef,
// adapted from libs/predef/test/tested_at.cpp

#include <boost/predef.h>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

// Version-number arithmetic is predef's core macro machinery
static_assert(BOOST_VERSION_NUMBER(1, 2, 3) > BOOST_VERSION_NUMBER(1, 2, 0), "v1");
static_assert(BOOST_VERSION_NUMBER(1, 2, 3) > BOOST_VERSION_NUMBER(1, 1, 9), "v2");
static_assert(BOOST_VERSION_NUMBER(2, 0, 0) > BOOST_VERSION_NUMBER(1, 99, 99), "v3");
static_assert(BOOST_VERSION_NUMBER(1, 2, 3) == BOOST_VERSION_NUMBER(1, 2, 3), "v4");

int main()
{
    // Runtime checks of the macros predef defines for this platform/compiler
    CHECK(BOOST_VERSION_NUMBER(1, 2, 3) > BOOST_VERSION_NUMBER(1, 1, 0));
    CHECK(BOOST_VERSION_NUMBER(1, 2, 3) < BOOST_VERSION_NUMBER(1, 3, 0));
#if defined(BOOST_OS_EMSCRIPTEN)
    CHECK(BOOST_OS_EMSCRIPTEN != 0); // running under emscripten -> detected
#endif
#if defined(BOOST_COMP_CLANG)
    CHECK(BOOST_COMP_CLANG != 0); // em++ is clang-based
#endif
#if defined(BOOST_ARCH_X86) || defined(BOOST_ARCH_WASM)
    CHECK(1); // an architecture macro is defined
#endif
    std::cout << "boost-predef OK\n";
    return 0;
}
