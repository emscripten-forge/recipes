// Functional test for boost-multiprecision, adapted from
// libs/multiprecision/test/git_issue_393.cpp and test_arithmetic

#include <boost/multiprecision/cpp_dec_float.hpp>
#include <boost/multiprecision/cpp_int.hpp>
#include <iostream>
#include <sstream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using boost::multiprecision::cpp_int;
    using boost::multiprecision::cpp_dec_float_50;

    // 30! exceeds 64-bit range: exact big-integer arithmetic.
    cpp_int fact = 1;
    for (int i = 2; i <= 30; ++i)
        fact *= i;
    cpp_int expected;
    std::istringstream iss("265252859812191058636308480000000");
    iss >> expected;
    CHECK(fact == expected);

    // Bit shifts and modular arithmetic on arbitrary-precision integers.
    cpp_int two_pow_100 = 1;
    for (int i = 0; i < 100; ++i)
        two_pow_100 <<= 1;
    CHECK((two_pow_100 >> 1) << 1 == two_pow_100);   // even
    CHECK(two_pow_100 % 3 == 1);                     // 2^100 mod 3 == 1
    cpp_int half = two_pow_100 / 2;
    CHECK(half * 2 == two_pow_100);

    // cpp_dec_float_50: sqrt to ~50 decimal digits, then square back.
    cpp_dec_float_50 two = 2;
    cpp_dec_float_50 root = sqrt(two);
    cpp_dec_float_50 diff = root * root - two;
    CHECK(diff > -1e-44 && diff < 1e-44);

    // Decimal addition/multiplication is exact.
    cpp_dec_float_50 x("0.1");
    cpp_dec_float_50 y = x + x + x + x + x + x + x + x + x + x;  // 1.0
    CHECK(y == cpp_dec_float_50("1"));
    CHECK(y / 4 == cpp_dec_float_50("0.25"));

    std::cout << "boost-multiprecision OK\n";
    return 0;
}
