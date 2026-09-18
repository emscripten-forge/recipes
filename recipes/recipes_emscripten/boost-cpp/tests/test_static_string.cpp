// Functional test for boost-static_string, adapted from
// libs/static_string/test/static_string.cpp

#include <boost/static_string.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

typedef boost::static_strings::basic_static_string< 64, char > sstr;

int main()
{
    sstr a;
    CHECK(a.empty());
    CHECK(a.size() == 0);

    a = "hello";
    CHECK(a.size() == 5);
    CHECK(a == "hello");
    CHECK(!a.empty());

    a += ", world";
    CHECK(a == "hello, world");
    CHECK(a.size() == 12);

    CHECK(a.find("world") == 7);
    CHECK(a.substr(7) == "world");
    CHECK(a.front() == 'h');
    CHECK(a.back() == 'd');
    CHECK(std::string(a.c_str()) == "hello, world");
    CHECK(a[0] == 'h' && a[11] == 'd');

    a.resize(3, 'x'); // shrink truncates
    CHECK(a == "hel");
    a.clear();
    a.resize(3, 'x'); // grow from empty fills with the character
    CHECK(a == "xxx");
    CHECK(a.size() == 3);

    a.clear();
    CHECK(a.empty());

    // capacity is fixed at compile time: value of N available without heap
    CHECK(a.max_size() <= 64);

    a = "fixed";
    std::string converted(a.begin(), a.end()); // iterators usable with std
    CHECK(converted == "fixed");

    std::cout << "boost-static_string OK\n";
    return 0;
}
