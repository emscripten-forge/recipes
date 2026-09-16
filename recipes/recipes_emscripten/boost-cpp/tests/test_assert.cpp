// Functional test for boost-assert , adapted from
// libs/assert/test/assert_test.cpp

#ifdef NDEBUG
#undef NDEBUG
#endif
#define BOOST_ENABLE_ASSERT_HANDLER
#include <boost/assert.hpp>
#include <iostream>
#include <string>
#include <cstring>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

static int g_asserts = 0;
static int g_msg_asserts = 0;

// declared by boost/assert.hpp when BOOST_ENABLE_ASSERT_HANDLER is defined
void boost::assertion_failed(char const* expr, char const* function,
                             char const* file, long line)
{
    (void)expr; (void)function; (void)file; (void)line;
    ++g_asserts;
}

void boost::assertion_failed_msg(char const* expr, char const* msg,
                                 char const* function, char const* file,
                                 long line)
{
    (void)expr; (void)msg; (void)function; (void)file; (void)line;
    ++g_msg_asserts;
}

int main()
{
    int x = 1;

    // passing assertions never reach the handler
    BOOST_ASSERT(x == 1);
    BOOST_ASSERT_MSG(2 + 2 == 4, "arithmetic");
    CHECK(g_asserts == 0);
    CHECK(g_msg_asserts == 0);

    // failing ones invoke the handler and execution continues
    BOOST_ASSERT(x == 0);
    BOOST_ASSERT_MSG(x == 2, "expected failure");
    CHECK(g_asserts == 1);
    CHECK(g_msg_asserts == 1);

    // BOOST_CURRENT_FUNCTION expands to the enclosing function name
    CHECK(std::string(BOOST_CURRENT_FUNCTION).find("main")
          != std::string::npos);

    std::cout << "boost-assert OK\n";
    return 0;
}
