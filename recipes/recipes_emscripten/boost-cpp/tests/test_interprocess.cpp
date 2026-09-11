// Functional test for boost-interprocess , adapted from
// libs/interprocess/example/doc_managed_external_buffer.cpp and
// libs/interprocess/test/adaptive_pool_test.cpp

#include <boost/interprocess/managed_external_buffer.hpp>
#include <boost/interprocess/allocators/adaptive_pool.hpp>
#include <boost/interprocess/allocators/allocator.hpp>
#include <boost/container/vector.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

int main()
{
    using namespace boost::interprocess;
    // plain in-memory segment over a static buffer - no OS shared memory
    const int memsize = 65536;
    static char static_buffer[memsize];

    managed_external_buffer objects_in_memory(create_only, &static_buffer[0], memsize);
    objects_in_memory.reserve_named_objects(100);

    // adaptive_pool allocator allocating inside the buffer
    typedef adaptive_pool<int, managed_external_buffer::segment_manager> pool_t;
    pool_t pool(objects_in_memory.get_segment_manager());
    pool_t::pointer p = pool.allocate(8);
    CHECK(p != 0);
    for (int i = 0; i < 8; ++i) p[i] = i * i;
    CHECK(p[3] == 9);
    pool.deallocate(p, 8);

    // STL vector placed inside the segment with a plain allocator
    typedef allocator<int, managed_external_buffer::segment_manager> alloc_t;
    typedef boost::container::vector<int, alloc_t> vec_t;
    vec_t* v = objects_in_memory.construct<vec_t>("MyVector")(alloc_t(objects_in_memory.get_segment_manager()));
    for (int i = 0; i < 10; ++i) v->push_back(i);
    CHECK(v->size() == 10);
    int sum = 0;
    for (vec_t::iterator it = v->begin(); it != v->end(); ++it) sum += *it;
    CHECK(sum == 45);
    CHECK(objects_in_memory.find<vec_t>("MyVector").first != 0);
    objects_in_memory.destroy<vec_t>("MyVector");
    std::cout << "boost-interprocess OK\n";
    return 0;
}
