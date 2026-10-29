// Functional test for boost-dynamic_bitse, adapted from
// libs/dynamic_bitset/example/example1.cpp (bit set/read/index) plus
// string construction and counting.

#include <boost/dynamic_bitset.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::dynamic_bitset<> x(5);  // all 0s
    x[0] = 1;
    x[1] = 1;
    x[4] = 1;

    CHECK(x.size() == 5);
    CHECK(x.count() == 3);                       // bits 0,1,4
    CHECK(x.to_ulong() == 19u);                  // 10011
    CHECK(x.test(4) && !x.test(2));

    x.flip();
    CHECK(x.count() == 2);
    CHECK(x.to_ulong() == 12u);                  // 01100

    boost::dynamic_bitset<> y(std::string("10110"));
    CHECK(y.size() == 5);
    CHECK(y.count() == 3);
    CHECK(y.to_ulong() == 22u);

    boost::dynamic_bitset<> z(y);
    z &= x;
    CHECK(z.to_ulong() == (22u & 12u));          // bitwise ops on dynamic size

    std::cout << "boost-dynamic_bitset OK\n";
    return 0;
}
