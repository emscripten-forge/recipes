// see https://github.com/python/cpython/blob/main/LICENSE for
// license of this file. This file is a modified version of
// it

#include "emscripten.h"
#include "stdio.h"

#ifdef __wasm32__
#define MAYBE_BIGINT(x) x
#else
#define MAYBE_BIGINT(x) BigInt(x)
#endif



// If we're running in node, report the UID of the user in the native system as
// the UID of the user. Since the nodefs will report the uid correctly, if we
// don't make getuid report it correctly too we'll see some permission errors.
// Normally __syscall_getuid32 is a stub that always returns 0 but it is
// defined with weak linkage so we can override it.
EM_JS(int, __syscall_getuid32_js, (void), {
    if (ENVIRONMENT_IS_NODE) {
        return process.getuid();
    }
    // Fall back to the stub case of returning 0.
    return 0;
})

int __syscall_getuid32(void) {
    return __syscall_getuid32_js();
}

EM_JS(int, __syscall_umask_js, (int mask), {
    if (ENVIRONMENT_IS_NODE) {
        try {
            return process.umask(mask);
        } catch(e) {
            // oops...
            // NodeJS docs: "In Worker threads, process.umask(mask) will throw an exception."
            // umask docs: "This system call always succeeds"
            return 0;
        }
    }
    // Fall back to the stub case of returning 0.
    return 0;
})

int __syscall_umask(int mask) {
    return __syscall_umask_js(mask);
}

#include <wasi/api.h>
#include <errno.h>
#include <fcntl.h>


#include <sys/ioctl.h>

int syscall_ioctl_orig(int fd, int request, void* varargs)
    __attribute__((__import_module__("env"),
                   __import_name__("__syscall_ioctl"), __warn_unused_result__));

int __syscall_ioctl(int fd, int request, void* varargs) {
    if (request == FIOCLEX || request == FIONCLEX) {
        return 0;
    }
    if (request == FIONBIO) {
        int flags = fcntl(fd, F_GETFL, 0);
        int nonblock = **((int**)varargs);
        if (flags < 0) {
            return -errno;
        }
        if (nonblock) {
            flags |= O_NONBLOCK;
        } else {
            flags &= (~O_NONBLOCK);
        }
        int res = fcntl(fd, F_SETFL, flags);
        if (res < 0) {
            return -errno;
        }
        return res;
    }
    return syscall_ioctl_orig(fd, request, varargs);
}