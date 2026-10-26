// Functional test for boost-align, adapted from
// libs/align/test/align_test.cpp


#include <boost/align.hpp>
#include <iostream>
#include <cstddef>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    alignas(64) char storage[128];

    // align() bumps a misaligned pointer up to the next boundary within space
    void* p = storage + 1;
    std::size_t space = sizeof(storage) - 1;
    void* q = boost::alignment::align(32, 1, p, space);
    CHECK(q != 0);
    CHECK(p == q); // p is advanced to the aligned address
    CHECK(boost::alignment::is_aligned(q, 32));
    // the buffer still fits another aligned allocation of the same size
    void* q3 = boost::alignment::align(32, 1, p, space);
    CHECK(q3 == q);

    // insufficient space: align() returns null and leaves p/space alone
    void* p2 = storage + 1;
    std::size_t space2 = 7;
    void* q2 = boost::alignment::align(8, 1, p2, space2);
    CHECK(q2 == 0);
    CHECK(p2 == storage + 1);
    CHECK(space2 == 7);

    // type alignment and integral align_up / align_down
    CHECK(boost::alignment::alignment_of<double>::value == alignof(double));
    CHECK((boost::alignment::alignment_of<long long>::value) == alignof(long long));
    CHECK(boost::alignment::align_up(std::size_t(5), std::size_t(4)) == 8);
    CHECK(boost::alignment::align_down(std::size_t(5), std::size_t(4)) == 4);

    std::cout << "boost-align OK\n";
    return 0;
}
