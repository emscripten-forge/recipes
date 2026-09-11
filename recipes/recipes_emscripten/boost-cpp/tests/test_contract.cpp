
#include <boost/contract.hpp>
#include <boost/contract/assert.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << std::endl; return 1; } } while (0)

// Failure handlers: the library defaults print and terminate, so install
// handlers that throw assertion_failure (the documented idiom for tests).
// Pre/postcondition handlers take boost::contract::from; check handler none.
static void throw_on_failure() { throw boost::contract::assertion_failure("test", 0, "contract violated"); }
static void throw_pre(boost::contract::from /*w*/)  { throw_on_failure(); }
static void throw_post(boost::contract::from /*w*/) { throw_on_failure(); }
static void throw_check() { throw_on_failure(); }

static int increment(int x)
{
    boost::contract::old_ptr<int> old_x = BOOST_CONTRACT_OLDOF(x);
    int r = x + 1;
    boost::contract::check c = boost::contract::function()
        .precondition([&] { BOOST_CONTRACT_ASSERT(x >= 0); })   // must throw, not return bool
        .postcondition([&] { BOOST_CONTRACT_ASSERT(r == *old_x + 1); });
    return r;
}

int main()
{
    boost::contract::set_precondition_failure(&throw_pre);
    boost::contract::set_postcondition_failure(&throw_post);
    boost::contract::set_check_failure(&throw_check);

    // contracts hold on valid calls
    CHECK(increment(0) == 1);
    CHECK(increment(41) == 42);

    // violated precondition must throw boost::contract::assertion_failure
    bool thrown = false;
    try {
        increment(-1);
    } catch (boost::contract::assertion_failure const&) {
        thrown = true;
    }
    CHECK(thrown);

    // BOOST_CONTRACT_CHECK inside a function body
    bool checked = false;
    try {
        int y = 3;
        BOOST_CONTRACT_CHECK(y > 10);   // violates -> throws
        (void)y;
    } catch (boost::contract::assertion_failure const&) {
        checked = true;
    }
    CHECK(checked);

    std::cout << "boost-contract OK (header-only)" << std::endl;
    return 0;
}
