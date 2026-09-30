// Functional test for boost-scope, adapted from
// libs/scope/test/run/defer_guard.cpp

#include <boost/scope/defer.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct inc_on_call
{
    int* p;
    explicit inc_on_call(int& r) : p(&r) {}
    void operator()() noexcept { ++*p; }
};

static void guarded(int& n, bool bail)
{
    boost::scope::defer_guard< inc_on_call > guard{ inc_on_call(n) };
    if (bail)
        return; // guard still fires on early return
    (void)guard;
}

int main()
{
    int n = 0;
    {
        boost::scope::defer_guard< inc_on_call > guard{ inc_on_call(n) };
        CHECK(n == 0); // not fired yet
    }
    CHECK(n == 1); // fired at scope exit

    n = 0;
    guarded(n, false);
    CHECK(n == 1); // normal return

    n = 0;
    guarded(n, true);
    CHECK(n == 1); // early return still runs the defer

    std::cout << "boost-scope OK\n";
    return 0;
}
