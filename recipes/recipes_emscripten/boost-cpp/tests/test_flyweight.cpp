// Functional test for boost-flyweight, adapted from
// libs/flyweight/test/test_basic.cpp

#include <boost/flyweight.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::flyweight<std::string> fw1("hello");
    boost::flyweight<std::string> fw2(std::string("hello"));
    boost::flyweight<std::string> fw3("world");

    // value semantics
    CHECK(fw1 == fw2);
    CHECK(fw1 != fw3);
    CHECK(fw1.get() == "hello");

    // interning: same value -> same shared representation
    CHECK(&fw1.get() == &fw2.get());
    CHECK(&fw1.get() != &fw3.get());

    // copy keeps sharing; reassignment switches the shared object
    boost::flyweight<std::string> fw4(fw1);
    CHECK(&fw4.get() == &fw1.get());
    fw4 = fw3;
    CHECK(fw4 == fw3);
    CHECK(&fw4.get() == &fw3.get());
    CHECK(&fw4.get() != &fw1.get());

    std::cout << "boost-flyweight OK\n";
    return 0;
}
