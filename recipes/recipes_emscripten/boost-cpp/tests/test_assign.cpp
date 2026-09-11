// Functional test for boost-assign , adapted from
// libs/assign/test/list_of.cpp and basic.cpp

#include <boost/assign.hpp>
#include <iostream>
#include <map>
#include <string>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::assign;

    // operator+= chains onto an existing container
    std::vector<int> v;
    v += 1, 2, 3, 4, 5;
    CHECK(v.size() == 5);
    CHECK(v[0] == 1 && v[2] == 3 && v[4] == 5);

    // list_of(...)(...) converts into any assignable container
    std::vector<std::string> names = list_of("a")("b")("c");
    CHECK(names.size() == 3);
    CHECK(names[1] == "b");

    std::map<std::string, int> m = map_list_of("one", 1)("two", 2)("three", 3);
    CHECK(m.size() == 3);
    CHECK(m["two"] == 2);
    CHECK(m.count("four") == 0);

    // repeat() expands the same value N times inside a list_of chain
    std::vector<int> reps = list_of(1).repeat(3, 9);
    CHECK(reps.size() == 4);
    CHECK(reps[0] == 1 && reps[1] == 9 && reps[3] == 9);

    std::cout << "boost-assign OK\n";
    return 0;
}
