// Functional test for boost-tuple (header-only), adapted from
// libs/tuple/test/quick.cpp

#include <boost/tuple/tuple.hpp>
#include <boost/tuple/tuple_comparison.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::tuple<int, int, int> tp(1, 2, 3);

    CHECK(boost::get<0>(tp) == 1);
    CHECK(boost::get<1>(tp) == 2);
    CHECK(boost::get<2>(tp) == 3);

    // boost::get on a non-const reference tuple is assignable.
    boost::get<1>(tp) = 20;
    CHECK(boost::get<1>(tp) == 20);

    // make_tuple builds a tuple; == compares elementwise.
    boost::tuple<int, std::string> a = boost::make_tuple(7, std::string("x"));
    boost::tuple<int, std::string> b = boost::make_tuple(7, std::string("x"));
    boost::tuple<int, std::string> c = boost::make_tuple(8, std::string("x"));
    CHECK(a == b);
    CHECK(!(a == c));
    CHECK(a < c);
    CHECK(boost::get<0>(a) == 7 && boost::get<1>(a) == "x");

    // tie unpacks a tuple into existing variables.
    int i = 0;
    double d = 0.0;
    boost::tie(i, d) = boost::make_tuple(5, 2.5);
    CHECK(i == 5);
    CHECK(d == 2.5);

    // Compile-time length of the tuple.
    CHECK((boost::tuples::length<boost::tuple<int, std::string> >::value == 2));

    std::cout << "boost-tuple OK\n";
    return 0;
}
