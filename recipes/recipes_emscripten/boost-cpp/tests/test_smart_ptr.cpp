// Functional test for boost-smart_ptr, adapted from
// libs/smart_ptr/test corpus

#include <boost/smart_ptr.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct counted
{
    static int alive;
    int v;
    int refs;
    explicit counted(int x) : v(x), refs(0) { ++alive; }
    ~counted() { --alive; }
};
int counted::alive = 0;

void intrusive_ptr_add_ref(counted* p) { ++p->refs; }
void intrusive_ptr_release(counted* p) { if (--p->refs == 0) delete p; }

static int g_deleted = 0;

int main()
{
    {
        boost::intrusive_ptr< counted > ip(new counted(7));
        {
            boost::intrusive_ptr< counted > ip2 = ip; // shared ownership
            CHECK(ip2->v == 7);
        }
        CHECK(counted::alive == 1);
        ip.reset();
    }
    CHECK(counted::alive == 0); // last reference released the object

    {
        boost::weak_ptr< int > wp;
        {
            boost::shared_ptr< int > sp(new int(42),
                [](int* p) { ++g_deleted; delete p; });
            wp = sp;
            CHECK(sp.use_count() == 1);
            CHECK(!wp.expired());
            boost::shared_ptr< int > lk = wp.lock(); // promote weak -> shared
            CHECK(lk && *lk == 42);
        }
        CHECK(g_deleted == 1); // custom deleter ran
        CHECK(wp.expired());   // owner gone
        CHECK(!wp.lock());
    }

    {
        boost::shared_ptr< counted > mc = boost::make_shared< counted >(3);
        CHECK(mc.unique());
        CHECK(counted::alive == 1);
    }
    CHECK(counted::alive == 0);

    std::cout << "boost-smart_ptr OK\n";
    return 0;
}
