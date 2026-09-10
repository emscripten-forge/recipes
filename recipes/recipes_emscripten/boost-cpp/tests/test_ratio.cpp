// Functional test for boost-ratio, adapted from
// libs/ratio/test/quick.cpp

#include <boost/ratio.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

typedef boost::ratio<5, 2> R1;
typedef boost::ratio<2, 7> R2;
typedef boost::ratio_multiply<R1, R2>::type R3;   // (5/2)*(2/7) = 10/14 -> 5/7
typedef boost::ratio_add<boost::ratio<1, 3>, boost::ratio<1, 6>>::type S;  // 1/2
typedef boost::ratio_subtract<boost::ratio<3, 4>, boost::ratio<1, 4>>::type T; // 1/2
typedef boost::ratio_divide<boost::ratio<1, 2>, boost::ratio<1, 8>>::type D;   // 4/1

static_assert(R3::num == 5 && R3::den == 7, "ratio_multiply reduces 10/14");
static_assert(S::num == 1 && S::den == 2, "ratio_add reduces 3/6");
static_assert(T::num == 1 && T::den == 2, "ratio_subtract");
static_assert(D::num == 4 && D::den == 1, "ratio_divide");

int main()
{
    // Runtime parity with the compile-time results.
    CHECK(R3::num == 5 && R3::den == 7);
    CHECK(S::num == 1 && S::den == 2);
    CHECK(T::num == 1 && T::den == 2);
    CHECK(D::num == 4 && D::den == 1);

    // Cross-type consistency: 1/3 + 1/3 = 2/3.
    typedef boost::ratio_add<boost::ratio<1, 3>, boost::ratio<1, 3>>::type Two3;
    CHECK(Two3::num == 2 && Two3::den == 3);

    std::cout << "boost-ratio OK\n";
    return 0;
}
