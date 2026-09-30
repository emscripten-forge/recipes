// Functional test for boost-msm , adapted from
// libs/msm/test/SimpleKleene.cpp

#include <boost/msm/backmp11/state_machine.hpp>
#include <boost/msm/front/functor_row.hpp>
#include <boost/msm/front/state_machine_def.hpp>
#include <boost/mp11/list.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace msm = boost::msm;
namespace front = msm::front;
using front::Row;
namespace mp11 = boost::mp11;

// Events
struct EvNext {};
struct EvBlocked {};

// Action functor counts how many transitions actually fire.
struct Act {
    template <class Event, class Fsm, class Source, class Target>
    void operator()(Event const&, Fsm&, Source&, Target&) { ++fired; }
    static int fired;
};
int Act::fired = 0;

// Guard functor: gates a row on a compile-time boolean.
template <bool Value>
struct Guard {
    template <class Event, class Fsm, class Source, class Target>
    bool operator()(Event const&, Fsm&, Source&, Target&) { return Value; }
};

// States record whether they are active (entry/exit hooks).
template <int I>
struct State : front::state<> {
    template <class Event, class Fsm>
    void on_entry(Event const&, Fsm&) { active = true; ++entered; }
    template <class Event, class Fsm>
    void on_exit(Event const&, Fsm&) { active = false; ++exited; }
    static int entered, exited;
    bool active = false;
};
template <int I> int State<I>::entered = 0;
template <int I> int State<I>::exited = 0;

struct Machine_ : front::state_machine_def<Machine_> {
    using transition_table = mp11::mp_list<
        Row<State<0>, EvNext, State<1>, Act, Guard<true>>,     // S0 -> S1
        Row<State<1>, EvNext, State<2>, Act, Guard<true>>,     // S1 -> S2
        Row<State<2>, EvBlocked, State<1>, Act, Guard<false>>  // blocked by guard
    >;
    using initial_state = State<0>;
};

int main()
{
    msm::backmp11::state_machine<Machine_> fsm;
    fsm.start();                                        // enters State<0>
    CHECK(State<0>::entered == 1);
    CHECK(fsm.get_state<State<0>>().active == true);

    fsm.process_event(EvNext());                        // State<0> -> State<1>
    CHECK(State<0>::exited == 1 && State<1>::entered == 1);
    CHECK(fsm.get_state<State<0>>().active == false);
    CHECK(fsm.get_state<State<1>>().active == true);
    CHECK(Act::fired == 1);

    fsm.process_event(EvNext());                        // State<1> -> State<2>
    CHECK(State<1>::exited == 1 && State<2>::entered == 1);
    CHECK(fsm.get_state<State<2>>().active == true);
    CHECK(Act::fired == 2);

    fsm.process_event(EvBlocked());                     // guard false: no move
    CHECK(fsm.get_state<State<2>>().active == true);
    CHECK(State<1>::entered == 1);
    CHECK(Act::fired == 2);

    fsm.stop();
    CHECK(State<2>::exited == 1);
    CHECK(fsm.get_state<State<2>>().active == false);

    std::cout << "boost-msm OK\n";
    return 0;
}
