// Functional test for boost-array, adapted from
// libs/array/test/array_hash.cpp

#include <boost/array.hpp>
#include <boost/functional/hash.hpp>
#include <algorithm>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    typedef boost::array<int, 5> barr;
    barr a = {{ 5, 3, 2, 1, 1 }};

    CHECK(a.size() == 5);
    CHECK(a[0] == 5);
    CHECK(a.at(2) == 2);
    CHECK(a.front() == 5);
    CHECK(a.back() == 1);
    CHECK(a.data() == &a[0]);
    CHECK(a.end() - a.begin() == 5);

    // usable with std algorithms
    std::sort(a.begin(), a.end());
    CHECK(a.front() == 1);
    CHECK(a.back() == 5);
    CHECK(a[0] == 1 && a[1] == 1 && a[2] == 2 && a[3] == 3 && a[4] == 5);

    // boost::hash of boost::array equals that of the equivalent C array
    // (corpus array_hash.cpp), and differs for different contents
    int carr[5] = { 1, 1, 2, 3, 5 };
    barr b = {{ 1, 1, 2, 3, 5 }};
    CHECK(boost::hash<barr>()(a) == boost::hash<barr>()(b));
    CHECK(boost::hash<barr>()(b) == boost::hash<int[5]>()(carr));
    barr c = {{ 9, 8, 7, 6, 0 }};
    CHECK(boost::hash<barr>()(c) != boost::hash<barr>()(b));

    std::cout << "boost-array OK\n";
    return 0;
}
