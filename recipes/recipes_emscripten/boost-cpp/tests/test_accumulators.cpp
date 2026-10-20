// Functional test for boost-accumulators, adapted from
// libs/accumulators/test/mean.cpp

#include <boost/accumulators/accumulators.hpp>
#include <boost/accumulators/statistics.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::accumulators;
    accumulator_set<double, features<tag::mean, tag::sum>> acc;
    acc(1.0);
    acc(2.0);
    acc(3.0);
    acc(4.0);
    CHECK(mean(acc) == 2.5);
    CHECK(sum(acc) == 10.0);
    std::cout << "boost-accumulators OK\n";
    return 0;
}
