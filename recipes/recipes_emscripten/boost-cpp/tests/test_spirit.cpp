// Functional test for boost-spirit, adapted from the spirit qi
// parser examples

#include <boost/spirit/include/qi.hpp>
#include <iostream>
#include <string>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace qi = boost::spirit::qi;

int main()
{
    // parse a comma-separated integer list straight into a container
    std::string in("1, 2, 3, 4");
    std::vector< int > v;
    std::string::iterator it = in.begin();
    bool ok = qi::phrase_parse(it, in.end(), qi::int_ % ',', qi::space, v);
    CHECK(ok);
    CHECK(it == in.end()); // whole input consumed
    CHECK(v.size() == 4);
    CHECK(v[0] == 1 && v[1] == 2 && v[2] == 3 && v[3] == 4);

    // partial parse: failure must leave the iterator before the end
    std::string bad("12, xyz");
    std::vector< int > w;
    std::string::iterator b2 = bad.begin();
    bool ok2 = qi::phrase_parse(b2, bad.end(), qi::int_ % ',', qi::space, w);
    CHECK(ok2);
    CHECK(w.size() == 1 && w[0] == 12);
    CHECK(b2 != bad.end()); // unconsumed garbage detected

    // hex integer parsing into a container
    std::string hx("1A, 2B, ff");
    std::vector< unsigned > u;
    std::string::iterator h = hx.begin();
    bool ok3 = qi::phrase_parse(h, hx.end(), qi::hex % ',', qi::space, u);
    CHECK(ok3 && h == hx.end());
    CHECK(u.size() == 3);
    CHECK(u[0] == 26 && u[1] == 43 && u[2] == 255);

    std::cout << "boost-spirit OK\n";
    return 0;
}
