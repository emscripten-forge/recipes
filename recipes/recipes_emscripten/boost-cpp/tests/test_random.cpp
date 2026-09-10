// Functional test for boost-random, adapted from libs/random/test

#include <boost/random.hpp>

int main()
{
    boost::random::mt19937 gen(42);

    // known first draw of MT19937 seeded with 42
    if (gen() != 1608637542UL) return 1;

    // 100 draws of uniform_int_distribution in [0, 100), all in range
    boost::random::mt19937 g2(42);
    boost::random::uniform_int_distribution<int> dist(0, 99);
    for (int i = 0; i < 100; ++i)
    {
        int v = dist(g2);
        if (v < 0 || v >= 100) return 1;
    }

    return 0;
}