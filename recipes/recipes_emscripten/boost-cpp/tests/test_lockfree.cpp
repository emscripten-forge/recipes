// Functional test for boost-lockfree , adapted from
// libs/lockfree/test/bounded_ticket_queue_test.cpp

#include <boost/lockfree/bounded_ticket_queue.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

using namespace boost::lockfree;

int main()
{
    bounded_ticket_queue<int> q(4);         // runtime-sized queue
    CHECK(q.empty());
    CHECK(q.push(1));
    CHECK(q.push(2));
    CHECK(q.push(3));
    CHECK(q.push(4));
    CHECK(!q.push(5));                      // queue full

    int out = 0;
    CHECK(q.pop(out) && out == 1);          // FIFO order
    CHECK(q.pop(out) && out == 2);
    CHECK(q.pop(out) && out == 3);
    CHECK(q.pop(out) && out == 4);
    CHECK(!q.pop(out));                     // queue empty
    CHECK(q.empty());

    bounded_ticket_queue<int> r(2);         // consume_one with callback
    r.push(7);
    r.push(8);
    bool ok1 = r.consume_one([&](int i) { out = i; });
    CHECK(ok1 && out == 7);
    bool ok2 = r.consume_one([&](int i) { out = i; });
    CHECK(ok2 && out == 8);
    CHECK(r.empty());
    std::cout << "boost-lockfree OK\n";
    return 0;
}
