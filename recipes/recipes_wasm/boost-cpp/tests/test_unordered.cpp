// Functional test for boost-unordered

#include <boost/unordered/concurrent_flat_map.hpp>
#include <string>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::unordered::concurrent_flat_map<std::string, int> m;
    CHECK(m.empty());

    m.emplace("alpha", 1);
    m.emplace("beta", 2);
    m.emplace("alpha", 3);          // duplicate key: rejected
    CHECK(m.size() == 2);
    CHECK(m.contains("alpha"));
    CHECK(!m.contains("gamma"));
    CHECK(m.count("beta") == 1);

    int seen = 0;
    CHECK(m.visit("alpha", [&](auto& kv) { seen = kv.second; }) == 1);
    CHECK(seen == 1);               // first value kept
    seen = 0;
    CHECK(m.visit("gamma", [&](auto& kv) { seen = kv.second; }) == 0);
    CHECK(seen == 0);

    CHECK(m.erase("alpha") == 1);
    CHECK(m.size() == 1);
    CHECK(!m.contains("alpha"));

    m.clear();
    CHECK(m.empty());
    std::cout << "boost-unordered OK\n";
    return 0;
}
