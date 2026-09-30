// Functional test for boost-tokenizer, adapted from
// libs/tokenizer/test/simple_example_1.cpp

#include <boost/tokenizer.hpp>
#include <iostream>
#include <string>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

static std::vector<std::string> collect(const boost::tokenizer<>& tok)
{
    std::vector<std::string> out;
    for (boost::tokenizer<>::iterator it = tok.begin(); it != tok.end(); ++it)
        out.push_back(*it);
    return out;
}

int main()
{
    // Default tokenizer: whitespace and punctuation separate, are dropped.
    {
        std::string s = "This is,  a test";
        boost::tokenizer<> tok(s);
        std::vector<std::string> v = collect(tok);
        CHECK(v.size() == 4);
        CHECK(v[0] == "This" && v[1] == "is" && v[2] == "a" && v[3] == "test");
    }

    // char_separator with two separator chars, empty tokens dropped.
    {
        std::string s = "a,b;c,d";
        boost::char_separator<char> sep(",;");
        boost::tokenizer<boost::char_separator<char> > tok(s, sep);
        std::vector<std::string> v;
        for (boost::tokenizer<boost::char_separator<char> >::iterator it = tok.begin();
             it != tok.end(); ++it)
            v.push_back(*it);
        CHECK(v.size() == 4);
        CHECK(v[0] == "a" && v[1] == "b" && v[2] == "c" && v[3] == "d");
    }

    // escaped_list_separator: CSV with quoted field containing commas
    // (corpus example from simple_example_2.cpp).
    {
        std::string csv = "Field 1,\"putting quotes around fields, allows commas\",Field 3";
        boost::tokenizer<boost::escaped_list_separator<char> > tok(csv);
        std::vector<std::string> v;
        for (boost::tokenizer<boost::escaped_list_separator<char> >::iterator it = tok.begin();
             it != tok.end(); ++it)
            v.push_back(*it);
        CHECK(v.size() == 3);
        CHECK(v[0] == "Field 1");
        CHECK(v[1] == "putting quotes around fields, allows commas"); // comma in quotes is kept
        CHECK(v[2] == "Field 3");
    }

    std::cout << "boost-tokenizer OK\n";
    return 0;
}
