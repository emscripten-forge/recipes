// Functional test for boost-container_hash, adapted from
// libs/container_hash/test/hash_container_test2.cpp

#include <boost/container_hash/hash.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::hash<int> hi;
    std::size_t h1 = hi(12345);
    CHECK(h1 == hi(12345));                 // deterministic
    CHECK(hi(1) != hi(2));

    boost::hash<long long> hll;
    CHECK(hll(9876543210LL) == hll(9876543210LL));

    boost::hash<unsigned int> hu;
    CHECK(hu(42u) == hu(42));

    boost::hash<std::string> hs;
    std::string a = "boost";
    std::string b = "boosu";
    CHECK(hs(a) == hs(a));
    CHECK(hs(a) == hs("boost"));            // value-based, not pointer-based
    CHECK(hs(a) != hs(b));

    std::size_t s1 = 0, s2 = 0;             // hash_combine reproducibility
    boost::hash_combine(s1, 42);
    boost::hash_combine(s1, std::string("x"));
    boost::hash_combine(s2, 42);
    boost::hash_combine(s2, std::string("x"));
    CHECK(s1 == s2);
    CHECK(s1 != 0);

    std::cout << "boost-container_hash OK\n";
    return 0;
}
