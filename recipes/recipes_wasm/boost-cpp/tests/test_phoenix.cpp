// Functional test for boost-phoenix, adapted from
// libs/phoenix/test/operator/comparison_tests.cpp and arithmetic usage

#include <boost/phoenix.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace phoenix = boost::phoenix;

int main()
{
    using phoenix::val;

    // Lazy actors built from values/operators, evaluated by calling ()
    CHECK((val(123) == 456)() == false);
    CHECK((val(123) != 456)() == true);
    CHECK((val(123) < 456)() == true);
    CHECK((val(123) <= 123)() == true);
    CHECK((val(2) + val(3) * val(4))() == 14);
    CHECK((val(20) / val(4))() == 5);
    CHECK((val(7) - val(2))() == 5);

    std::cout << "boost-phoenix OK\n";
    return 0;
}
