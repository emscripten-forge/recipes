// Functional test for boost-ptr_container, adapted from
// libs/ptr_container/test/ptr_vector_size.cpp and no_exceptions.cpp

#include <boost/ptr_container/ptr_vector.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::ptr_vector<int> v;

    v.push_back(new int(30));
    v.push_back(new int(10));
    v.push_back(new int(20));

    // The container owns the pointees; elements are accessed by value.
    CHECK(v.size() == 3);
    CHECK(v.front() == 30 && v.back() == 20);
    CHECK(v[1] == 10);

    // Sequence adapter sort orders the pointed-to values.
    v.sort();
    CHECK(v[0] == 10 && v[1] == 20 && v[2] == 30);

    // Erase deletes the pointee and shifts the rest.
    v.erase(v.begin() + 1);
    CHECK(v.size() == 2 && v[0] == 10 && v[1] == 30);

    v.push_back(new int(5));
    v.sort();
    CHECK(v.front() == 5 && v.back() == 30);
    CHECK(v.front() + v.back() == 35);

    std::cout << "boost-ptr_container OK\n";
    return 0;
}
