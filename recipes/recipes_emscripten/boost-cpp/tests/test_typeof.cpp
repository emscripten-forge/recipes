// Functional test for boost-typeof, adapted from
// libs/typeof/test/type.cpp

#include <boost/typeof/typeof.hpp>
#include <vector>
#include <type_traits>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    int i = 5;

    // BOOST_AUTO captures the exact type of an expression
    BOOST_AUTO(d, i * 0.5);       // int * double -> double
    BOOST_AUTO(k, i * 2);         // int * int -> int
    CHECK(d == 2.5);
    CHECK(k == 10);

    // BOOST_TYPEOF names the type in a static assertion
    static_assert(std::is_same<BOOST_TYPEOF(i * 0.5), double>::value, "typeof(i*0.5)");
    static_assert(std::is_same<BOOST_TYPEOF(&i), int*>::value, "typeof(&i)");

    // container iterator idiom (docs use BOOST_AUTO for this)
    std::vector<int> v;
    v.push_back(7);
    v.push_back(8);
    BOOST_AUTO(it, v.begin());
    CHECK(*it == 7);
    BOOST_AUTO(it2, it + 1);
    CHECK(*it2 == 8);

    std::cout << "boost-typeof OK\n";
    return 0;
}
