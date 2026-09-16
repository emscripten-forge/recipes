// Functional test for boost-heap, adapted from
// libs/heap/test/binomial_heap_test.cpp

#include <boost/heap/binomial_heap.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

int main()
{
    typedef boost::heap::binomial_heap<int> pri_queue;
    pri_queue pq;
    pq.push(2);
    pq.push(5);
    pq.push(1);
    pq.push(3);
    CHECK(pq.size() == 4);
    CHECK(!pq.empty());
    CHECK(pq.top() == 5);   // max element on top
    pq.pop();
    CHECK(pq.top() == 3);
    pq.pop();
    CHECK(pq.top() == 2);
    pq.pop();
    CHECK(pq.top() == 1);
    pq.pop();
    CHECK(pq.empty());

    // ordered iteration over the remaining heap (max-heap: descending)
    pri_queue pq2;
    pq2.push(7);
    pq2.push(4);
    pq2.push(9);
    int prev = 2147483647;
    bool ordered = true;
    for (pri_queue::ordered_iterator it = pq2.ordered_begin();
         it != pq2.ordered_end(); ++it)
    {
        if (*it > prev) ordered = false;
        prev = *it;
    }
    CHECK(ordered);
    CHECK(prev == 4); // last element of the descending run
    std::cout << "boost-heap OK\n";
    return 0;
}
