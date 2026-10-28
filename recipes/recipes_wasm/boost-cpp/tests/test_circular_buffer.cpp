// Functional test for boost-circular_buffer, adapted from
// libs/circular_buffer/example/circular_buffer_example.cpp
#include <boost/circular_buffer.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::circular_buffer<int> cb(3);
    CHECK(cb.capacity() == 3);
    CHECK(cb.empty());
    CHECK(cb.size() == 0);

    cb.push_back(1);
    cb.push_back(2);
    cb.push_back(3);
    CHECK(cb.full());
    CHECK(cb.front() == 1 && cb.back() == 3);
    CHECK(cb[0] == 1 && cb[1] == 2 && cb[2] == 3);

    cb.push_back(4);                       // overwrites 1
    cb.push_back(5);                       // overwrites 2
    CHECK(cb.size() == 3 && cb.full());
    CHECK(cb[0] == 3 && cb[1] == 4 && cb[2] == 5);

    cb.pop_back();                         // removes 5
    cb.pop_front();                        // removes 3
    CHECK(cb.size() == 1 && !cb.empty());
    CHECK(cb[0] == 4);
    CHECK(cb.front() == 4 && cb.back() == 4);

    cb.push_back(6);
    cb.push_back(7);
    CHECK(cb.size() == 3);
    CHECK(cb[0] == 4 && cb[1] == 6 && cb[2] == 7);

    std::cout << "boost-circular_buffer OK\n";
    return 0;
}
