// Functional test for boost-bind adapted from
// libs/bind/test/bind_test.cpp and bind_rel_test.cpp

#include <boost/bind.hpp>
#include <iostream>
#include <algorithm>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

long f_2(long a, long b) { return a + 10 * b; } // from corpus bind_test.cpp

struct X
{
    long n;
    long add(long a) const { return n + a; }
};

int main()
{
    using boost::placeholders::_1;
    using boost::placeholders::_2;

    // free function, bound arguments and placeholder reordering
    CHECK(boost::bind(f_2, 2, 5)() == 52);
    CHECK(boost::bind(f_2, _1, 5)(2) == 52);
    CHECK(boost::bind(f_2, _2, _1)(4, 3) == 43); // f_2(3, 4)

    // member function and member data binding
    X x = { 7 };
    CHECK(boost::bind(&X::add, _1, 3)(x) == 10);
    CHECK(boost::bind(&X::n, _1)(x) == 7);

    // lazy comparison between bind expressions drives std::sort
    std::vector<X> xs;
    xs.push_back(X{ 3 });
    xs.push_back(X{ 1 });
    xs.push_back(X{ 2 });
    std::sort(xs.begin(), xs.end(),
              boost::bind(&X::n, _1) < boost::bind(&X::n, _2));
    CHECK(xs[0].n == 1 && xs[1].n == 2 && xs[2].n == 3);

    std::cout << "boost-bind OK\n";
    return 0;
}
