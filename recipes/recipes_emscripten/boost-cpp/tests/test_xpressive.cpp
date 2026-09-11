#include <boost/xpressive/xpressive.hpp>
#include <string>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

using namespace boost::xpressive;

int main()
{
    std::string s("born on 12/07/1986, wasn't it?");
    smatch what;

    // dynamically compiled regex: parse at runtime and capture groups
    sregex date = sregex::compile("(\\d{2})/(\\d{2})/(\\d{4})");
    CHECK(regex_search(s, what, date));
    CHECK(what[0].str() == "12/07/1986");
    CHECK(what[1].str() == "12");
    CHECK(what[2].str() == "07");
    CHECK(what[3].str() == "1986");

    std::string none("nothing here");
    CHECK(!regex_search(none, what, date));

    // static regex built from expression templates with marks s1/s2
    sregex dash = (s1 = +_d) >> '-' >> (s2 = +_d);
    std::string t("part 42-7 done");
    smatch w2;
    CHECK(regex_search(t, w2, dash));
    CHECK(w2[1].str() == "42");
    CHECK(w2[2].str() == "7");

    std::cout << "boost-xpressive OK\n";
    return 0;
}
