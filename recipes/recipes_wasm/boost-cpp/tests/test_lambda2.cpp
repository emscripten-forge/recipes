// Functional test for boost-lambda2 , adapted from
// libs/lambda2/test/quick.cpp

#include <boost/lambda2.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::lambda2;
    // Arithmetic placeholders
    CHECK((_1 + _2 * _3)(1, 2, 3) == 1 + 2 * 3);
    CHECK((_1 - _2)(10, 4) == 6);
    CHECK((_1 * _2)(6, 7) == 42);
    // Placeholder binds leftmost args, later args in order
    int x = 5;
    CHECK((_1 + _2 + x)(1, 2) == 8);
    std::cout << "boost-lambda2 OK\n";
    return 0;
}
