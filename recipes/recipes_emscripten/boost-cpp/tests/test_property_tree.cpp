// Functional test for boost-property_tree, adapted from
// libs/property_tree/test/sandbox.cpp and test_json_parser*.cpp 

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <iostream>
#include <sstream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::property_tree;

    std::istringstream iss("{\"a\": 1, \"b\": {\"c\": \"x\"}}");
    ptree pt;
    read_json(iss, pt);

    // Nested integer and string access through the tree path syntax.
    CHECK(pt.get<int>("a") == 1);
    CHECK(pt.get<std::string>("b.c") == "x");
    CHECK(pt.get_child("b").count("c") == 1);

    // Missing keys take the supplied default instead of throwing.
    CHECK(pt.get("missing", -1) == -1);
    CHECK(pt.get<std::string>("b.missing", "none") == "none");

    // put() inserts/overwrites nodes.
    pt.put("a", 41);
    CHECK(pt.get<int>("a") == 41);

    // Round-trip the tree back to JSON text.
    std::ostringstream oss;
    write_json(oss, pt);
    CHECK(oss.str().find("41") != std::string::npos);

    std::cout << "boost-property_tree OK\n";
    return 0;
}
