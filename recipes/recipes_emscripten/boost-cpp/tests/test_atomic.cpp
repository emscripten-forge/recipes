// Functional test for boost-atomic, adapted from
// libs/atomic/test/atomicity.cpp

#include <boost/atomic.hpp>

int main()
{
    boost::atomic<int> counter(0);

    // 1000 relaxed increments, then a load must observe the exact total
    for (int i = 0; i < 1000; ++i)
        counter.fetch_add(1, boost::memory_order_relaxed);
    if (counter.load(boost::memory_order_relaxed) != 1000) return 1;

    // release/acquire store-load pair
    boost::atomic<int> flag(0);
    flag.store(7, boost::memory_order_release);
    if (flag.load(boost::memory_order_acquire) != 7) return 1;

    return 0;
}