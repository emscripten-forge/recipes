// C code calling poll(), like OpenSSL's QUIC reactor. Emscripten >= 6.0.1
// keeps nfds_t 32-bit on wasm64, so this imports poll as (i64, i32, i32).
#include <poll.h>

int c_poll_user(void) {
    struct pollfd fd = {0, POLLIN, 0};
    return poll(&fd, 1, 0);
}
