// Functional test for boost-hof, adapted from
// libs/hof/test/alias.cpp and libs/hof/test/compose.cpp

#include <boost/hof.hpp>
#include <boost/hof/alias.hpp>
#include <boost/hof/compose.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

struct foo
{
    int i;
    foo(int i_) : i(i_) {}
};

int inc(int x) { return x + 1; }
int dbl(int x) { return x * 2; }

int main()
{
    // alias wraps a value, alias_value unwraps it
    boost::hof::alias<int> ai = 5;
    CHECK(boost::hof::alias_value(ai) == 5);
    boost::hof::alias_inherit<foo> af = foo{7};
    CHECK(boost::hof::alias_value(af).i == 7);

    // compose applies functions right to left: inc(dbl(3)) == 7
    auto f = boost::hof::compose(inc, dbl);
    CHECK(f(3) == 7);
    CHECK(f(0) == 1);

    // partial application: compose with only the first function known
    auto g = boost::hof::compose(inc);
    CHECK(g(10) == 11);
    std::cout << "boost-hof OK\n";
    return 0;
}
