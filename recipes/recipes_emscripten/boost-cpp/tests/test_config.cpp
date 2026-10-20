// Functional test for boost-config , adapted from
// libs/config/test/ 

#include <boost/config.hpp>
#include <boost/version.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

#if defined(BOOST_CXX_VERSION)
static_assert(BOOST_CXX_VERSION >= 201402, "need C++14+");
#endif

int main()
{
    std::cout << "BOOST_VERSION=" << BOOST_VERSION
              << " BOOST_LIB_VERSION=" << BOOST_LIB_VERSION << "\n";
    CHECK(BOOST_VERSION >= 109000);          // Boost 1.90+
    CHECK((BOOST_VERSION / 100) % 100 >= 84); // minor >= 84 (env: 1.92)
    CHECK(BOOST_LIB_VERSION[0] == '1' && BOOST_LIB_VERSION[1] == '_');

#if defined(BOOST_NO_CXX11_NULLPTR)
    bool has_nullptr = false;
#else
    bool has_nullptr = true;
#endif
    CHECK(has_nullptr);
#if defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
    bool has_rvalue = false;
#else
    bool has_rvalue = true;
#endif
    CHECK(has_rvalue);

    std::cout << "boost-config OK\n";
    return 0;
}
