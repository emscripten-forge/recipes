// Functional test for boost-bimap, adapted from
// libs/bimap/example/simple_bimap.cpp
#include <boost/bimap.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    typedef boost::bimap<std::string, int> results_bimap;
    typedef results_bimap::value_type position;

    results_bimap results;
    results.insert(position("Argentina", 1));
    results.insert(position("Spain", 2));
    results.insert(position("Germany", 3));
    results.insert(position("France", 4));

    CHECK(results.size() == 4);
    CHECK(!results.insert(position("Germany", 3)).second); // duplicate rejected

    // lookup by key on either side
    CHECK(results.left.at("Germany") == 3);
    CHECK(results.right.at(1) == "Argentina");
    CHECK(results.left.count("Spain") == 1);
    CHECK(results.right.count(9) == 0);

    // iteration order on the right view follows the second key
    results_bimap::right_map::const_iterator it = results.right.begin();
    CHECK(it->second == "Argentina"); // right view keyed by int, value = name
    CHECK(results.right.find(2)->second == "Spain");

    // erase through the left view keeps both sides consistent
    results.left.erase(results.left.find("France"));
    CHECK(results.size() == 3);
    CHECK(results.right.count(4) == 0);
    CHECK(results.left.count("France") == 0);

    std::cout << "boost-bimap OK\n";
    return 0;
}
