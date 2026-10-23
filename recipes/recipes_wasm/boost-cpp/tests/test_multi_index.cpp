// Functional test for boost-multi_index, adapted from
// libs/multi_index/test/test_composite_key_main.cpp

#include <boost/multi_index/composite_key.hpp>
#include <boost/multi_index/member.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index_container.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct employee {
    int id;
    std::string name;
    int age;
    employee(int i, std::string n, int a) : id(i), name(n), age(a) {}
};

typedef boost::multi_index_container<
    employee,
    boost::multi_index::indexed_by<
        boost::multi_index::ordered_unique<
            boost::multi_index::member<employee, int, &employee::id> >,
        boost::multi_index::ordered_unique<
            boost::multi_index::composite_key<
                employee,
                boost::multi_index::member<employee, std::string, &employee::name>,
                boost::multi_index::member<employee, int, &employee::age>
            >
        >
    >
> employee_set;

int main()
{
    employee_set es;
    es.insert(employee(1, "Ann", 27));
    es.insert(employee(2, "Ann", 30));   // same name, different age: OK
    es.insert(employee(3, "Bob", 25));
    es.insert(employee(4, "Bob", 31));
    CHECK(es.size() == 4u);

    // Index 0: lookup by unique id.
    employee_set::nth_index<0>::type& by_id = es.get<0>();
    CHECK(by_id.find(3) != by_id.end());
    CHECK(by_id.find(3)->name == "Bob");
    CHECK(by_id.find(9) == by_id.end());

    // Index 1: composite key (name, age) orders by name, then age as tiebreak.
    employee_set::nth_index<1>::type& by_name_age = es.get<1>();
    std::string seen[4];
    int i = 0;
    for (employee_set::nth_index<1>::type::const_iterator it = by_name_age.begin();
         it != by_name_age.end(); ++it, ++i)
        seen[i] = it->name + ":" + std::to_string(it->age);
    CHECK(seen[0] == "Ann:27" && seen[1] == "Ann:30");
    CHECK(seen[2] == "Bob:25" && seen[3] == "Bob:31");

    // Composite uniqueness: (Bob,25) duplicate is rejected.
    CHECK(!es.insert(employee(5, "Bob", 25)).second);

    // Same element reachable through both indices (projection).
    employee_set::nth_index<0>::type::iterator it0 = by_id.find(2);
    employee_set::nth_index<1>::type::const_iterator it1 =
        es.project<1>(it0);
    CHECK(it1 != by_name_age.end() && it1->age == 30);

    // Erase through the id index shrinks the whole container.
    CHECK(by_id.erase(3) == 1u);
    CHECK(es.size() == 3u);

    std::cout << "boost-multi_index OK\n";
    return 0;
}
