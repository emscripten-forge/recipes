// Functional test for boost-statechart, adapted from
// libs/statechart/test/TransitionTest.cpp

#include <boost/statechart/state_machine.hpp>
#include <boost/statechart/simple_state.hpp>
#include <boost/statechart/transition.hpp>
#include <boost/statechart/event.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace sc = boost::statechart;

struct EvGo : sc::event< EvGo > {};
struct EvBack : sc::event< EvBack > {};

static int g_idle_entries = 0;
static int g_run_entries = 0;

struct Idle;
struct Running;

struct Machine : sc::state_machine< Machine, Idle > {};

struct Idle : sc::simple_state< Idle, Machine >
{
    typedef sc::transition< EvGo, Running > reactions;
    Idle() { ++g_idle_entries; }
};

struct Running : sc::simple_state< Running, Machine >
{
    typedef sc::transition< EvBack, Idle > reactions;
    Running() { ++g_run_entries; }
};

int main()
{
    g_idle_entries = 0;
    g_run_entries = 0;

    Machine m;
    m.initiate(); // enters the initial state Idle
    CHECK(g_idle_entries == 1);
    CHECK(g_run_entries == 0);
    CHECK(m.state_cast< const Idle* >() != 0); // currently in Idle
    CHECK(m.state_cast< const Running* >() == 0);

    m.process_event(EvGo()); // transition Idle -> Running
    CHECK(g_run_entries == 1);
    CHECK(g_idle_entries == 1);
    CHECK(m.state_cast< const Running* >() != 0);

    m.process_event(EvBack()); // transition Running -> Idle
    CHECK(g_idle_entries == 2); // Idle entered a second time
    CHECK(g_run_entries == 1);  // Running entered only once
    CHECK(m.state_cast< const Idle* >() != 0);

    CHECK(!m.terminated());
    m.terminate();
    CHECK(m.terminated());

    std::cout << "boost-statechart OK\n";
    return 0;
}
