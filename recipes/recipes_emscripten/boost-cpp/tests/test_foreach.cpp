// Functional test for boost-foreach, adapted from
// libs/foreach/test/misc.cpp

#include <boost/foreach.hpp>
#include <iostream>
#include <string>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    std::vector<int> v;
    v.push_back(1); v.push_back(2); v.push_back(3); v.push_back(4);

    int sum = 0;
    BOOST_FOREACH (int x, v)
        sum += x;
    CHECK(sum == 10);

    int evens = 0;
    BOOST_FOREACH (int x, v)
        if (x % 2 == 0) ++evens;
    CHECK(evens == 2);

    std::string s = "boost";
    int letters = 0;
    BOOST_FOREACH (char c, s)
        if (c >= 'a' && c <= 'z') ++letters;
    CHECK(letters == 5);

    std::cout << "boost-foreach OK\n";
    return 0;
}
