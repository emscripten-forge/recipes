// Functional test for boost-compat, adapted from
// libs/compat/test/bind_back_fn_test.cpp

#include <boost/compat/bind_back.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int f2(int x1, int x2) { return 10 * x1 + x2; }
int f3(int x1, int x2, int x3) { return 100 * x1 + 10 * x2 + x3; }

int main()
{
    CHECK(boost::compat::bind_back(f2)(1, 2) == 12);
    CHECK(boost::compat::bind_back(f2, 1)(2) == 21);         // binds trailing arg
    CHECK(boost::compat::bind_back(f2, 1, 2)() == 12);
    CHECK(boost::compat::bind_back(f3, 1)(2, 3) == 231);
    CHECK(boost::compat::bind_back(f3, 1, 2)(3) == 312);
    CHECK(boost::compat::bind_back(f3, 1, 2, 3)() == 123);

    auto mul = [](int a, int b) { return a * b; };
    CHECK(boost::compat::bind_back(mul, 6)(7) == 42);

    std::cout << "boost-compat OK\n";
    return 0;
}
