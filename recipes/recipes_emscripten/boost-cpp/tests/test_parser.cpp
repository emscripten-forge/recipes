// Functional test for boost-parser , adapted from
// libs/parser/example/trivial.cpp

#include <boost/parser/parser.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    namespace bp = boost::parser;
    auto const doubles = bp::double_ >> *(',' >> bp::double_);

    auto r = bp::parse(std::string("1,2,3.5"), doubles);
    CHECK(bool(r));
    CHECK(r->size() == 3u);
    CHECK((*r)[0] == 1.0);
    CHECK((*r)[1] == 2.0);
    CHECK((*r)[2] == 3.5);

    auto bad = bp::parse(std::string("1,"), doubles);
    CHECK(!bool(bad));

    auto n = bp::parse(std::string("42"), bp::uint_);
    CHECK(bool(n));
    CHECK(*n == 42u);

    std::cout << "boost-parser OK\n";
    return 0;
}
