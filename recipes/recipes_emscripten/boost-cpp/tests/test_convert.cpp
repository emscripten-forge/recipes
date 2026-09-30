#include <boost/convert.hpp>
#include <boost/convert/lexical_cast.hpp>
#include <boost/convert/strtol.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::cnv::strtol cnv;

    CHECK(boost::convert<int>("123", cnv).value_or(-1) == 123);
    CHECK(boost::convert<int>("-11", cnv).value_or(-1) == -11);
    CHECK(boost::convert<int>("3456", cnv).value_or(-1) == 3456);
    CHECK(boost::convert<int>("not an int", cnv).value_or(-1) == -1); // fallback
    CHECK(boost::convert<double>("3.5", cnv).value_or(0.0) == 3.5);
    CHECK(!boost::convert<int>("not an int", cnv));                    // no value

    boost::cnv::lexical_cast lcnv;
    CHECK(boost::convert<int>("2017", lcnv).value_or(0) == 2017);
    CHECK(boost::convert<std::string>(2016, lcnv).value_or("") == "2016");

    std::cout << "boost-convert OK\n";
    return 0;
}
