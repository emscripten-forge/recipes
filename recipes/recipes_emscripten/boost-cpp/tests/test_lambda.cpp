// Functional test for boost-lambda, adapted from
// libs/lambda/test/quick.cpp and libs/lambda/test/operator_tests_simple.cpp

#include <boost/lambda/lambda.hpp>
#include <boost/lambda/if.hpp>
#include <vector>
#include <algorithm>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::lambda;

    CHECK((_1 + _2)(1, 2) == 3);
    CHECK((_1 * _2 + _3)(2, 3, 1) == 7);
    CHECK((_1 - _2)(10, 4) == 6);
    CHECK((_1 < _2)(3, 5));
    CHECK(!(_1 < _2)(5, 5));

    // if_then_else_return picks one branch at call time (like std::max)
    CHECK(if_then_else_return(_1 < _2, _2, _1)(3, 42) == 42);
    CHECK(if_then_else_return(_1 < _2, _2, _1)(42, 3) == 42);

    // use in std::transform: map each value through x*x + 1
    std::vector<int> v;
    for (int i = 0; i < 4; ++i) v.push_back(i);
    std::vector<int> w(4);
    std::transform(v.begin(), v.end(), w.begin(), (_1 * _1 + 1));
    CHECK(w[0] == 1);
    CHECK(w[1] == 2);
    CHECK(w[2] == 5);
    CHECK(w[3] == 10);
    std::cout << "boost-lambda OK\n";
    return 0;
}
