// Functional test for boost-gil, adapted from
// libs/gil/test/core/histogram/access.cpp

#include <boost/gil/histogram.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace gil = boost::gil;

int main()
{
    // 1-D histogram over int values
    gil::histogram<int> h1;
    h1(1) = 3;
    CHECK(h1(1) == 3);
    CHECK(h1(3) == 0);

    // 3-D histogram (int, char, string) axes
    gil::histogram<int, char, std::string> h2;
    h2(1, 'a', "A") = 4;
    CHECK(h2(1, 'a', "A") == 4);
    CHECK(h2(1, 'a', "B") == 0);

    // copy construction preserves counts
    gil::histogram<int> h3(h1);
    CHECK(h3(1) == 3);

    std::cout << "boost-gil OK\n";
    return 0;
}
