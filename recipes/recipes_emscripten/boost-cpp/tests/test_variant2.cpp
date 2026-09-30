// Functional test for boost-variant2, adapted from
// libs/variant2/test/quick.cpp.

#include <boost/variant2.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

using namespace boost::variant2;

int main()
{
    variant<int, double> v(42);
    CHECK(get<0>(v) == 42);

    v.emplace<double>(2.5);
    CHECK(holds_alternative<double>(v));
    CHECK(get<1>(v) == 2.5);

    double acc = 0.0;
    visit([&](auto x) { acc += static_cast<double>(x); }, v);
    CHECK(acc == 2.5);

    v = 9;                        // assignment switches back to int
    CHECK(holds_alternative<int>(v));
    CHECK(get_if<double>(&v) == nullptr);

    variant<int, double> d;       // default: first alternative
    CHECK(get<0>(d) == 0);

    std::cout << "boost-variant2 OK\n";
    return 0;
}
