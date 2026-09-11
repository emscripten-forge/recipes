// Functional test for boost-hana, adapted from
// libs/hana/example/first.cpp and libs/hana/test/ sequence usage

#include <boost/hana.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace hana = boost::hana;

int main()
{
    constexpr auto t = hana::make_tuple(1, 2, 3);

    // tuple access at runtime
    CHECK(hana::at_c<0>(t) == 1);
    CHECK(hana::at_c<2>(t) == 3);
    static_assert(hana::size(t) == 3u, "tuple size");

    // runtime fold over the heterogeneous tuple
    int s = hana::fold_left(t, 0, [](int acc, int x) { return acc + x; });
    CHECK(s == 6);

    // transform maps each element
    auto t2 = hana::transform(t, [](int x) { return x * 10; });
    CHECK(hana::at_c<1>(t2) == 20);

    // pair access (compile-time checked like the upstream example)
    constexpr auto p = hana::make_pair(1, 'x');
    static_assert(hana::first(p) == 1, "pair first");
    CHECK(hana::second(p) == 'x');

    std::cout << "boost-hana OK\n";
    return 0;
}
