// Functional test for boost-icl , adapted from
// libs/icl/example/interval_container_/interval_container.cpp

#include <boost/icl/interval_map.hpp>
#include <boost/icl/interval_set.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::icl;
    typedef interval_map<int, int> map_t;

    // overlapping right-open intervals accumulate their codomain values
    map_t m;
    m += std::make_pair(map_t::interval_type::right_open(0, 3), 1);
    m += std::make_pair(map_t::interval_type::right_open(2, 5), 2);
    m += std::make_pair(map_t::interval_type::right_open(4, 6), 1);

    // [0,2):1  [2,3):3  [3,4):2  [4,5):3  [5,6):1
    CHECK(m.iterative_size() == 5);
    int sum1 = 0, sum3 = 0;
    for (map_t::const_iterator it = m.begin(); it != m.end(); ++it)
    {
        if (it->second == 1) ++sum1;
        if (it->second == 3) ++sum3;
    }
    CHECK(sum1 == 2);
    CHECK(sum3 == 2);

    // interval_set merges touching intervals: [1,3) + [3,5) = [1,5)
    interval_set<int> s;
    s.add(interval<int>::right_open(1, 3));
    s.add(interval<int>::right_open(3, 5));
    CHECK(s.iterative_size() == 1);
    CHECK(contains(s, 4));
    CHECK(!contains(s, 5));
    std::cout << "boost-icl OK\n";
    return 0;
}
