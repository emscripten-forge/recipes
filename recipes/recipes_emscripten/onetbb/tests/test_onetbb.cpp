#include <tbb/tbb.h>
#include <tbb/concurrent_vector.h>
#include <tbb/parallel_for.h>
#include <tbb/task_arena.h>
#include <cassert>
#include <iostream>
#include <vector>

int main() {
    // 1. Check max concurrency is at least 1
    int max_concurrency = tbb::this_task_arena::max_concurrency();
    std::cout << "max_concurrency: " << max_concurrency << std::endl;
    assert(max_concurrency >= 1);

    // 2. Test concurrent_vector basic operations
    tbb::concurrent_vector<int> cv;
    for (int i = 0; i < 100; ++i) {
        cv.push_back(i);
    }
    assert(cv.size() == 100);
    for (int i = 0; i < 100; ++i) {
        assert(cv[i] == i);
    }

    // 3. Test parallel_for (may run single-threaded on WASM, but must compile
    //    and execute correctly)
    std::vector<int> data(100, 0);
    tbb::parallel_for(0, 100, [&data](int i) {
        data[i] = i * 2;
    });
    for (int i = 0; i < 100; ++i) {
        assert(data[i] == i * 2);
    }

    // 4. Test task_arena
    tbb::task_arena arena(1);
    arena.execute([&] {
        std::vector<int> local(10, 0);
        tbb::parallel_for(0, 10, [&local](int i) {
            local[i] = i + 1;
        });
        for (int i = 0; i < 10; ++i) {
            assert(local[i] == i + 1);
        }
    });

    std::cout << "All tests passed!" << std::endl;
    return 0;
}
