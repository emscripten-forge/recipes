// Functional test for boost-url, adapted from
// libs/url/test/unit/url.cpp

#include <boost/url/url.hpp>
#include <boost/url/parse.hpp>
#include <string>

int main()
{
    namespace urls = boost::urls;

    urls::url u = urls::parse_uri(
        "https://user@example.com:8080/path/to?q=1#frag").value();

    if (u.scheme() != "https") return 1;
    if (u.host() != "example.com") return 1;
    if (u.port() != "8080") return 1;
    if (u.port_number() != 8080) return 1;
    if (u.segments().size() != 2) return 1;
    if (u.segments().front() != "path") return 1;
    if (u.segments().back() != "to") return 1;
    if (u.query() != "q=1") return 1;
    if (u.fragment() != "frag") return 1;

    // serialize and reparse: identical url and identical buffer
    std::string s = u.buffer();
    urls::url u2 = urls::parse_uri(s).value();
    if (u2 != u) return 1;
    if (u2.buffer() != s) return 1;

    return 0;
}