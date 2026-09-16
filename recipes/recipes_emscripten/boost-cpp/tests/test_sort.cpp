// Functional test for boost-sort, adapted from
// libs/sort/test/integer_sort_test.cpp

#include <boost/sort/sort.hpp>
#include <algorithm>
#include <iostream>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    // deterministic input with duplicates and negatives
    std::vector< int > v;
    v.reserve(256);
    for (int i = 0; i < 256; ++i)
        v.push_back((i * 37 + 11) % 101 - 50);

    std::vector< int > w = v;
    long long before = 0;
    for (std::size_t i = 0; i < v.size(); ++i) before += v[i];

    boost::sort::spreadsort::spreadsort(v.begin(), v.end()); // hybrid radix sort
    CHECK(std::is_sorted(v.begin(), v.end()));

    boost::sort::pdqsort(w.begin(), w.end()); // pattern-defeating quicksort (lives in boost::sort)
    CHECK(std::is_sorted(w.begin(), w.end()));

    long long after = 0;
    for (std::size_t i = 0; i < v.size(); ++i) after += v[i];
    CHECK(after == before); // same multiset, reordered

    std::vector< int > small{ 5, -3, 0, -3, 7, 2, 0 };
    boost::sort::spreadsort::spreadsort(small.begin(), small.end());
    CHECK(std::is_sorted(small.begin(), small.end()));
    CHECK(small[0] == -3 && small[1] == -3 && small.back() == 7);

    std::cout << "boost-sort OK\n";
    return 0;
}
