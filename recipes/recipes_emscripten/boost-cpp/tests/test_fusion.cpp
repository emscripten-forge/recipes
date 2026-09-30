// Functional test for boost-fusion, adapted from
// libs/fusion/test/quick.cpp

#include <boost/fusion/include/accumulate.hpp>
#include <boost/fusion/include/at_c.hpp>
#include <boost/fusion/include/size.hpp>
#include <boost/fusion/include/vector.hpp>
#include <functional>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::fusion;

    vector<int, char, std::string> stuff(1, 'x', "howdy");
    CHECK(at_c<0>(stuff) == 1);
    CHECK(at_c<1>(stuff) == 'x');
    CHECK(at_c<2>(stuff) == "howdy");

    // vector is a random-access sequence: assign through at_c
    at_c<0>(stuff) = 7;
    CHECK(at_c<0>(stuff) == 7);

    vector<int, int, int> nums(1, 2, 3);
    static_assert(result_of::size<vector<int, int, int> >::value == 3, "fusion size");
    CHECK(accumulate(nums, 0, std::plus<int>()) == 6);

    std::cout << "boost-fusion OK\n";
    return 0;
}
