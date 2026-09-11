// Functional test for boost-container, adapted from
// libs/container/test/flat_map_test.cpp

#include <boost/container/stable_vector.hpp>
#include <boost/container/flat_map.hpp>

int main()
{
    using namespace boost::container;

    // stable_vector: push_back then erase keeps remaining elements intact
    stable_vector<int> sv;
    for (int i = 0; i < 10; ++i) sv.push_back(i);
    if (sv.size() != 10) return 1;
    sv.erase(sv.begin() + 3); // remove value 3
    if (sv.size() != 9) return 1;
    if (sv[3] != 4) return 1; // value 4 shifts into slot 3

    // flat_map: store, lookup by key, at(), find(), contains()
    flat_map<int, int> fm;
    fm.emplace(1, 10);
    fm.emplace(2, 20);
    fm.emplace(3, 30);
    if (fm.at(2) != 20) return 1;
    if (fm.find(1) == fm.end()) return 1;
    if (fm.find(42) != fm.end()) return 1;
    if (!fm.contains(3)) return 1;

    return 0;
}