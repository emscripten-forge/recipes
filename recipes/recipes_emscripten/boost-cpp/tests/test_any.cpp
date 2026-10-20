// Functional test for boost-any, adapted from
// libs/any/test/any_test.cpp

#include <boost/any.hpp>
#include <iostream>
#include <string>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::any a;
    CHECK(a.empty());

    a = 42;
    CHECK(!a.empty());
    CHECK(a.type() == typeid(int));
    CHECK(boost::any_cast<int>(a) == 42);

    a = std::string("boost");
    CHECK(a.type() == typeid(std::string));
    CHECK(boost::any_cast<std::string>(a) == "boost");

    // non-throwing pointer form: wrong type yields null, right type yields ptr
    CHECK(boost::any_cast<int>(&a) == 0);
    CHECK(boost::any_cast<std::string>(&a) != 0);
    CHECK(*boost::any_cast<std::string>(&a) == "boost");

    // large object (heap-stored) round trip
    std::vector<int> big(100, 7);
    a = big;
    CHECK(boost::any_cast<std::vector<int> >(a).size() == 100);
    CHECK(boost::any_cast<std::vector<int> >(a)[99] == 7);

    a = boost::any();
    CHECK(a.empty());

    std::cout << "boost-any OK\n";
    return 0;
}
