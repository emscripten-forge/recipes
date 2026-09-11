// Functional test for boost-detail, exercising the small
// sequence helpers shipped in boost/detail/algorithm.hpp (any_if,
// container_contains).
#include <boost/detail/algorithm.hpp>
#include <iostream>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    std::vector<int> v { 1, 2, 3, 4, 5 };

    CHECK(boost::container_contains(v, 3));
    CHECK(!boost::container_contains(v, 9));
    CHECK(boost::container_contains(v.begin(), v.end(), 1));

    CHECK(boost::any_if(v, [](int x) { return x > 4; }));
    CHECK(!boost::any_if(v, [](int x) { return x > 5; }));
    CHECK(boost::any_if(v.begin(), v.end(), [](int x) { return x % 2 == 0; }));

    std::vector<int> empty;
    CHECK(!boost::any_if(empty, [](int) { return true; }));

    std::cout << "boost-detail OK\n";
    return 0;
}
