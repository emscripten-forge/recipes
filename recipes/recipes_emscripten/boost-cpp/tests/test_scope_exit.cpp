// Functional test for boost-scope_exit, adapted from
// libs/scope_exit/example/scope_guard.cpp
#include <boost/scope_exit.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

static int g_rollbacks = 0;

static void txn(bool fail)
{
    bool commit = false;
    BOOST_SCOPE_EXIT(&g_rollbacks, &commit) {
        if (!commit)
            ++g_rollbacks; // rollback the uncommitted transaction
    } BOOST_SCOPE_EXIT_END

    if (fail)
        return; // aborted: scope exit must roll back
    commit = true; // committed: no rollback
}

int main()
{
    g_rollbacks = 0;
    txn(false);
    CHECK(g_rollbacks == 0); // committed path: guard was a no-op

    txn(true);
    CHECK(g_rollbacks == 1); // aborted path: rollback ran

    // by-value capture snapshots the value at guard creation,
    // by-reference capture sees later changes
    int v = 10;
    {
        BOOST_SCOPE_EXIT(&g_rollbacks, v) {
            g_rollbacks += v;
        } BOOST_SCOPE_EXIT_END
        v = 100; // only visible through &-captured variables
    }
    CHECK(g_rollbacks == 11); // 1 + captured 10, not 101

    std::cout << "boost-scope_exit OK\n";
    return 0;
}
