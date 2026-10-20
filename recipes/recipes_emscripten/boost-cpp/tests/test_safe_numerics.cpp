// Functional test for boost-safe_numerics, adapted from
// libs/safe_numerics/example/example16.cpp and test_add_automatic.cpp
#include <boost/safe_numerics/safe_integer.hpp>
#include <boost/safe_numerics/automatic.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::safe_numerics;

    // Checked implicit conversion (example16): in-range values convert freely.
    safe<long> y = 97;
    CHECK(long(y) == 97);

    // Automatic policy: operands are promoted so the product of two int8
    // values (100*100 = 10000, far beyond int8 range) never overflows.
    safe<std::int8_t, automatic> a = 100;
    safe<std::int8_t, automatic> b = 100;
    auto p = a * b;
    CHECK(p == 10000);
    CHECK(p / 100 == 100);

    // Mixed-size arithmetic keeps full precision under promotion.
    safe<std::int8_t, automatic> small = 5;
    auto scaled = small * 1000;         // would overflow int8 under native rules
    CHECK(scaled == 5000);

    // Plain checked arithmetic with the automatic policy.
    safe<int, automatic> x = 12345;
    CHECK(x + 1 == 12346);
    CHECK(x - x == 0);
    CHECK(x > 12344 && x < 12346);

    std::cout << "boost-safe_numerics OK\n";
    return 0;
}
