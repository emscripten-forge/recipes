// Functional test for boost-move, adapted from
// libs/move/test/move_core.cpp and the movable class pattern in
// libs/move/example/movable.hpp

#include <boost/move/move.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct movable
{
    BOOST_MOVABLE_BUT_NOT_COPYABLE(movable)

public:
    movable(int v = 0) : value(v) {}
    movable(BOOST_RV_REF(movable) o) : value(o.value)
    {
        o.value = -1;
        ++num_moves;
    }
    movable& operator=(BOOST_RV_REF(movable) o)
    {
        value = o.value;
        o.value = -1;
        ++num_moves;
        return *this;
    }
    int value;
    static int num_moves;
};

int movable::num_moves = 0;

int main()
{
    movable a(41), b(42);
    CHECK(movable::num_moves == 0);

    movable c(boost::move(a));      // move-construct: steals a's value
    CHECK(c.value == 41);
    CHECK(a.value == -1);           // moved-from state

    b = boost::move(c);             // move-assign: steals c's value
    CHECK(b.value == 41);
    CHECK(c.value == -1);
    CHECK(movable::num_moves == 2);
    std::cout << "boost-move OK\n";
    return 0;
}
