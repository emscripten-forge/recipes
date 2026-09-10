// Functional test for boost-range, adapted from
// libs/range/test/algorithm_example.cpp and adaptors.cpp

#include <boost/range.hpp>
#include <boost/range/algorithm.hpp>
#include <boost/range/adaptors.hpp>
#include <boost/range/numeric.hpp>
#include <iostream>
#include <iterator>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    std::vector<int> v{3, 1, 2};

    CHECK(boost::distance(v) == 3);

    boost::sort(v);                     // range algorithm on the whole range
    CHECK(v.front() == 1 && v.back() == 3);

    CHECK(boost::accumulate(v, 0) == 6); // 1 + 2 + 3
    CHECK(boost::count(v, 2) == 1);

    std::vector<int> w;
    boost::copy(v | boost::adaptors::reversed, std::back_inserter(w));
    CHECK(w.size() == 3 && w[0] == 3 && w[1] == 2 && w[2] == 1);

    // Adaptor composition: take the even tail elements in reverse order.
    std::vector<int> u;
    boost::copy(v | boost::adaptors::reversed | boost::adaptors::strided(2),
                std::back_inserter(u));
    CHECK(u.size() == 2 && u[0] == 3 && u[1] == 1);

    std::cout << "boost-range OK\n";
    return 0;
}
