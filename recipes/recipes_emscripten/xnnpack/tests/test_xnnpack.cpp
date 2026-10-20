#include <xnnpack.h>
#include <assert.h>
#include <iostream>

int xnnpack_test_smoke(void) {
    enum xnn_status status = xnn_initialize(NULL);
    assert(status == xnn_status_success && "xnn_initialize failed");

    status = xnn_deinitialize();
    assert(status == xnn_status_success && "xnn_deinitialize failed");
    std::cout << "XNNPACK smoke test passed!" << std::endl;
    return 0;
}
