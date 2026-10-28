// Functional test for boost-property_map_parallel , adapted from
// libs/property_map
#include <boost/config.hpp>  // defines BOOST_STATIC_CONSTANT used by basic_reduce.hpp
#include <boost/property_map/parallel/basic_reduce.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    boost::parallel::basic_reduce<int> reduce;

    // No remote value: yields a default-constructed T for any key.
    CHECK(reduce(42) == 0);
    CHECK(reduce("some-key") == 0);

    // With local and remote values, the remote value always wins.
    int local = 7, remote = 42;
    CHECK(reduce(1, local, remote) == 42);

    // Non-default resolvers (that would combine values) are not used here.
    CHECK(!reduce.non_default_resolver);

    // Drop-in usage: resolve a sequence of (local, remote) pairs per key.
    int acc = 0;
    for (int key = 0; key < 4; ++key)
        acc += reduce(key, local + key, remote);
    CHECK(acc == 4 * remote);

    std::cout << "boost-property_map_parallel OK\n";
    return 0;
}
