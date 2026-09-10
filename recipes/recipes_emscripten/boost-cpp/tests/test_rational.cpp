// Functional test for boost-rational, adapted from
// libs/rational/test/constexpr_test.cpp and rational_test.cpp

#include <boost/rational.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::rational<int> zero;
    CHECK(zero.numerator() == 0 && zero.denominator() == 1);

    // Construction normalizes: 2/4 -> 1/2.
    boost::rational<int> half(2, 4);
    CHECK(half.numerator() == 1 && half.denominator() == 2);

    boost::rational<int> third(1, 3);
    CHECK(half + third == boost::rational<int>(5, 6));
    CHECK(half - third == boost::rational<int>(1, 6));
    CHECK(half * third == boost::rational<int>(1, 6));
    CHECK(half / third == boost::rational<int>(3, 2));

    CHECK(third * 3 == 1);              // mixed arithmetic with plain ints
    CHECK(half > third && half != third);

    CHECK(boost::rational_cast<double>(boost::rational<int>(1, 4)) == 0.25);

    // C++11 constexpr construction, per the upstream constexpr_test.
    constexpr boost::rational<int> ci(3);
    static_assert(ci.numerator() == 3 && ci.denominator() == 1, "rational constexpr");

    std::cout << "boost-rational OK\n";
    return 0;
}
