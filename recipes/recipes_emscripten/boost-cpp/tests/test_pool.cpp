// Functional test for boost-pool, adapted from
// libs/pool/test/test_bug_3349.cpp

#include <boost/pool/pool.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::pool<> p(256, 4);
    CHECK(p.get_requested_size() == 256);

    void* block1 = p.ordered_malloc(1);
    CHECK(block1 != 0);
    void* block2 = p.ordered_malloc(4);
    CHECK(block2 != 0);
    CHECK(block1 != block2);

    p.ordered_free(block1);
    CHECK(p.release_memory()); // unused block 1 is returned to the system

    void* block3 = p.ordered_malloc(1);
    CHECK(block3 != 0);
    p.ordered_free(block3);
    p.ordered_free(block2);

    std::cout << "boost-pool OK\n";
    return 0;
}
