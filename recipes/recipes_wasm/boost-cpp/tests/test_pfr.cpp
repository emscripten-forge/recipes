// Functional test for boost-pfr, adapted from
// libs/pfr/test/core/run/motivating_example.cpp

#include <boost/pfr.hpp>
#include <iostream>


#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct my_struct
{
    int i;
    char c;
    double d;
};

int main()
{
    my_struct s{100, 'H', 3.141593};

    CHECK(boost::pfr::tuple_size<my_struct>::value == 3);
    CHECK(boost::pfr::get<0>(s) == 100);
    CHECK(boost::pfr::get<1>(s) == 'H');
    CHECK(boost::pfr::get<2>(s) == 3.141593);

    boost::pfr::get<0>(s) = 7;
    CHECK(boost::pfr::get<0>(s) == 7);

    auto t = boost::pfr::structure_to_tuple(s);
    CHECK(std::get<0>(t) == 7);
    CHECK(std::get<1>(t) == 'H');
    CHECK(std::get<2>(t) == 3.141593);

    std::cout << "boost-pfr OK\n";
    return 0;
}
