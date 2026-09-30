// Functional test for boost-lexical_cast, adapted from
// libs/lexical_cast/test/lexical_cast_test.cpp

#include <boost/lexical_cast.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    // String -> arithmetic
    CHECK(boost::lexical_cast<int>("1234") == 1234);
    CHECK(boost::lexical_cast<long>("-17") == -17L);
    CHECK(boost::lexical_cast<double>("3.5") == 3.5);
    // Arithmetic -> string
    CHECK(boost::lexical_cast<std::string>(42) == "42");
    CHECK(boost::lexical_cast<std::string>(2.25) == "2.25");
    std::cout << "boost-lexical_cast OK\n";
    return 0;
}
