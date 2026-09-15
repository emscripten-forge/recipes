// Functional test for boost-variant

#include <boost/variant.hpp>
#include <boost/variant/static_visitor.hpp>
#include <boost/variant/apply_visitor.hpp>
#include <string>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct double_it : boost::static_visitor<int>
{
    int operator()(int i) const { return 2 * i; }
    int operator()(std::string const& s) const { return static_cast<int>(s.size()); }
};

int main()
{
    boost::variant<int, std::string> v(21);
    CHECK(boost::get<int>(v) == 21);
    CHECK(v.which() == 0);

    v = std::string("boost");
    CHECK(v.which() == 1);
    CHECK(boost::get<std::string>(v) == "boost");

    v = 21;
    CHECK(boost::apply_visitor(double_it(), v) == 42);

    v = std::string("ab");
    CHECK(boost::apply_visitor(double_it(), v) == 2);

    std::cout << "boost-variant OK\n";
    return 0;
}
