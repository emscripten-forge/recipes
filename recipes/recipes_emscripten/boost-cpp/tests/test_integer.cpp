// Functional test for boost-integer, adapted from
// libs/integer/test/extended_euclidean_test.cpp

#include <boost/integer.hpp>
#include <boost/integer/extended_euclidean.hpp>
#include <boost/integer/common_factor.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

int main()
{
    using boost::integer::extended_euclidean;
    using boost::integer::gcd;

    // Bezout identity: gcd(240,46)=2 and 240*x + 46*y == 2
    boost::integer::euclidean_result_t<int> u = extended_euclidean(240, 46);
    CHECK(u.gcd == 2);
    CHECK(u.gcd == gcd(240, 46));
    CHECK(240 * u.x + 46 * u.y == 2);

    // coprime pair
    u = extended_euclidean(17, 5);
    CHECK(u.gcd == 1);
    CHECK(17 * u.x + 5 * u.y == 1);

    // one argument divides the other
    u = extended_euclidean(64, 8);
    CHECK(u.gcd == 8);
    CHECK(u.x == 0 || u.y == 0);

    CHECK(gcd(1071, 462) == 21);
    CHECK(gcd(0, 5) == 5);

    // integer_traits from the umbrella header
    CHECK(boost::integer_traits<unsigned char>::const_max == 255);
    std::cout << "boost-integer OK\n";
    return 0;
}
