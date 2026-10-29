// Functional test for boost-decimal, adapted from
// libs/decimal/example/basic_arithmetic.cpp (decimal64_t arithmetic is
// exact for decimal fractions, unlike binary floating point).
#include <boost/decimal.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using boost::decimal::decimal64_t;

    // 0.1 + 0.2 == 0.3 exactly in decimal floating point
    constexpr decimal64_t a {"0.1"};
    constexpr decimal64_t b {"0.2"};
    constexpr decimal64_t c {a + b};
    static_assert(c == decimal64_t {"0.3"}, "0.1+0.2 must be exact");
    CHECK(c == decimal64_t {"0.3"});

    constexpr decimal64_t neg {"-5.5"};
    static_assert(neg == -a * decimal64_t {"55"} , "negation/multiplication");
    CHECK(boost::decimal::abs(neg) == decimal64_t {"5.5"});

    constexpr decimal64_t big {"12345678901234.5"};  // 16 sig digits: exact
    constexpr decimal64_t quarter {"0.25"};
    static_assert(big + quarter == decimal64_t {"12345678901234.75"});
    CHECK(big * decimal64_t {"2"} == decimal64_t {"24691357802469"});

    std::cout << "boost-decimal OK\n";
    return 0;
}
