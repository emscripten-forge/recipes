// Functional test for boost-signals2, adapted from
// libs/signals2/example/custom_combiners.cpp

#include <boost/signals2.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

static int g_sum = 0;
static int g_pings = 0;

static void add_to_sum(int x) { g_sum += x; }
static void ping(int) { ++g_pings; }
static int doubler(int x) { return x * 2; }
static int tripler(int x) { return x * 3; }

int main()
{
    boost::signals2::signal< void(int) > sig;
    boost::signals2::connection c1 = sig.connect(&add_to_sum);
    boost::signals2::connection c2 = sig.connect(&ping);

    sig(3);
    sig(4);
    CHECK(g_sum == 7);
    CHECK(g_pings == 2);
    CHECK(c1.connected());

    c2.disconnect(); // slot removed
    sig(5);
    CHECK(g_sum == 12);
    CHECK(g_pings == 2);
    CHECK(!c2.connected());

    {
        boost::signals2::scoped_connection sc = sig.connect(&ping);
        sig(1);
        CHECK(g_pings == 3);
    } // scoped connection auto-disconnects
    sig(1);
    CHECK(g_pings == 3);

    // default combiner returns the last slot's value, in connection order
    boost::signals2::signal< int(int) > sq;
    sq.connect(&doubler);
    sq.connect(&tripler);
    CHECK(sq(5) == 15);

    std::cout << "boost-signals2 OK\n";
    return 0;
}
