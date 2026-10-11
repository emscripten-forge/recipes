#include <tbb/scalable_allocator.h>
#include <cassert>
#include <cstdlib>
#include <iostream>
#include <cstring>

int main() {
    // 1. scalable_malloc / scalable_free
    void* p = scalable_malloc(1024);
    assert(p != nullptr);
    std::memset(p, 0xAB, 1024);
    scalable_free(p);

    // 2. scalable_calloc
    int* arr = static_cast<int*>(scalable_calloc(100, sizeof(int)));
    assert(arr != nullptr);
    for (int i = 0; i < 100; ++i) {
        assert(arr[i] == 0);
    }
    scalable_free(arr);

    // 3. scalable_realloc
    char* s = static_cast<char*>(scalable_malloc(32));
    assert(s != nullptr);
    std::memcpy(s, "hello tbbmalloc", 15);
    s = static_cast<char*>(scalable_realloc(s, 64));
    assert(s != nullptr);
    scalable_free(s);

    // 4. scalable_aligned_malloc / scalable_aligned_free
    void* ap = scalable_aligned_malloc(256, 64);
    assert(ap != nullptr);
    assert(reinterpret_cast<std::uintptr_t>(ap) % 64 == 0);
    scalable_aligned_free(ap);

    // 5. scalable_posix_memalign
    void* pp = nullptr;
    int ret = scalable_posix_memalign(&pp, 64, 128);
    assert(ret == 0);
    assert(pp != nullptr);
    assert(reinterpret_cast<std::uintptr_t>(pp) % 64 == 0);
    scalable_free(pp);

    std::cout << "tbbmalloc tests passed!" << std::endl;
    return 0;
}
