#include <cpuinfo.h>
#include <stdio.h>
#include <assert.h>

int main(void) {
    /* Initialize cpuinfo */
    bool ok = cpuinfo_initialize();
    assert(ok && "cpuinfo_initialize() failed");
    printf("cpuinfo initialized successfully\n");

    /* Processor / core / package counts must be >= 1 */
    uint32_t processors = cpuinfo_get_processors_count();
    uint32_t cores = cpuinfo_get_cores_count();
    uint32_t packages = cpuinfo_get_packages_count();
    assert(processors >= 1 && "processors count must be >= 1");
    assert(cores >= 1 && "cores count must be >= 1");
    assert(packages >= 1 && "packages count must be >= 1");
    printf("Processors: %u\n", processors);
    printf("Cores:      %u\n", cores);
    printf("Packages:   %u\n", packages);

    /* Cache info - just check it doesn't crash */
    uint32_t l1i = cpuinfo_get_l1i_caches_count();
    uint32_t l1d = cpuinfo_get_l1d_caches_count();
    uint32_t l2  = cpuinfo_get_l2_caches_count();
    printf("L1i caches: %u\n", l1i);
    printf("L1d caches: %u\n", l1d);
    printf("L2  caches: %u\n", l2);

    /* Max cache size must be > 0 when any cache is present */
    if (l1i > 0 || l1d > 0 || l2 > 0) {
        uint32_t max_cache = cpuinfo_get_max_cache_size();
        assert(max_cache > 0 && "max_cache_size must be > 0 when caches exist");
        printf("Max cache size: %u bytes\n", max_cache);
    }

    cpuinfo_deinitialize();
    printf("All cpuinfo tests passed!\n");
    return 0;
}
