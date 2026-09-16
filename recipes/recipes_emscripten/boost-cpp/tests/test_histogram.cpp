// Functional test for boost-histogram, adapted from
// libs/histogram/test/histogram_test.cpp

#include <boost/histogram.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::histogram;
    // 5 integer bins over [0,5), no under/overflow bins
    auto h = make_histogram(
        axis::integer<int, axis::null_type, axis::option::none_t>(0, 5));
    h(1);
    h(1);
    h(2);
    h(3);
    h(4);
    h(4);
    CHECK(h.rank() == 1);
    CHECK(h.axis().size() == 5);
    CHECK(h.size() == 5);
    CHECK(h.at(0) == 0);
    CHECK(h.at(1) == 2);
    CHECK(h.at(2) == 1);
    CHECK(h.at(3) == 1);
    CHECK(h.at(4) == 2);
    std::cout << "boost-histogram OK\n";
    return 0;
}
