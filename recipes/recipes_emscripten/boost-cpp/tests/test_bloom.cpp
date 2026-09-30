// Functional test for boost-bloom, adapted from
// libs/bloom/example/basic.cpp

#include <boost/bloom.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using filter = boost::bloom::filter<std::string, 5>;
    filter f(1000000);                     // 1,000,000-bit filter
    f.insert("hello");
    f.insert("Boost");
    CHECK(f.may_contain("hello"));
    CHECK(f.may_contain("Boost"));

    for (int i = 0; i < 50; ++i)           // more inserts must not evict
        f.insert("item" + std::to_string(i));
    CHECK(f.may_contain("hello"));
    CHECK(f.may_contain("item7"));
    CHECK(f.may_contain("item49"));

    boost::bloom::filter<int, 5> g(100000);
    for (int i = 0; i < 1000; ++i)
        g.insert(i * 7);
    CHECK(g.may_contain(0));
    CHECK(g.may_contain(7 * 999));

    std::cout << "boost-bloom OK\n";
    return 0;
}
