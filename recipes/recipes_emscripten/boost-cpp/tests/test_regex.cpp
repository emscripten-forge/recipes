// Functional test for boost-regex, adapted from libs/regex/test/regress

#include <boost/regex.hpp>
#include <string>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << std::endl; return 1; } } while (0)

int main()
{
    std::string text = "the quick brown fox jumps over the lazy dog";

    // --- search + group extraction ---
    boost::regex q("q(ui)ck");
    boost::smatch m;
    CHECK(boost::regex_search(text, m, q));
    CHECK(m.size() == 2);
    CHECK(m[0].str() == "quick");
    CHECK(m[1].str() == "ui");
    CHECK(m.position() == 4);

    // --- full match vs partial ("the.*" would actually full-match) ---
    CHECK(!boost::regex_match(text, boost::regex("quick")));        // partial: no full match
    CHECK(boost::regex_match("abc123", boost::regex("[a-z]+\\d+")));

    // --- replace ---
    std::string replaced = boost::regex_replace(
        text, boost::regex("quick"), std::string("slow"));
    CHECK(replaced == "the slow brown fox jumps over the lazy dog");

    // --- iterate all matches ---
    boost::regex word("\\w+");
    boost::sregex_iterator it(text.begin(), text.end(), word), end;
    int words = 0;
    for (; it != end; ++it) ++words;
    CHECK(words == 9);

    // --- case-insensitive flag ---
    CHECK(boost::regex_search("THE QUICK", boost::regex("quick", boost::regex::icase)));

    // --- character classes + repetition ---
    CHECK(boost::regex_match("2026-09-05", boost::regex("\\d{4}-\\d{2}-\\d{2}")));

    std::cout << "boost-regex OK" << std::endl;
    return 0;
}
