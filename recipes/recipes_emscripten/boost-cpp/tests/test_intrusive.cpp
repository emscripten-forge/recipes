// Functional test for boost-intrusive, adapted from
// libs/intrusive/example/doc_any_hook.cpp

#include <vector>
#include <boost/intrusive/any_hook.hpp>
#include <boost/intrusive/slist.hpp>
#include <boost/intrusive/list.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

using namespace boost::intrusive;

class MyClass : public any_base_hook<>
{
    int int_;
public:
    any_member_hook<> member_hook_;
    MyClass(int i = 0) : int_(i) {}
    int get_int() const { return int_; }
};

int main()
{
    // base hook of each object doubles as an slist hook
    typedef any_to_slist_hook<base_hook<any_base_hook<> > > BaseSlistOption;
    typedef slist<MyClass, BaseSlistOption> BaseSList;
    // member hook doubles as a list hook
    typedef any_to_list_hook<member_hook<MyClass, any_member_hook<>,
                              &MyClass::member_hook_> > MemberListOption;
    typedef list<MyClass, MemberListOption> MemberList;

    std::vector<MyClass> values;
    for (int i = 0; i < 5; ++i) values.push_back(MyClass(i));

    BaseSList base_slist;
    MemberList member_list;
    for (int i = 0; i < 5; ++i)
    {
        base_slist.push_front(values[i]);   // reversed order
        member_list.push_back(values[i]);   // original order
    }
    CHECK(base_slist.size() == 5);
    CHECK(member_list.size() == 5);

    // verify order through the intrusive containers
    BaseSList::iterator bit = base_slist.begin();
    MemberList::iterator mit = member_list.begin();
    for (int i = 0; i < 5; ++i, ++bit, ++mit)
    {
        CHECK(bit->get_int() == 4 - i);
        CHECK(mit->get_int() == i);
    }
    std::cout << "boost-intrusive OK\n";
    return 0;
}
