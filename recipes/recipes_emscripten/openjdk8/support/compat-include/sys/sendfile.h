/*
 * sys/sendfile.h -- compatibility header for building OpenJDK with
 * Emscripten.  sendfile() reports EINVAL so FileChannel.transferTo() falls
 * back to copying through a buffer.
 */
#ifndef _COMPAT_SYS_SENDFILE_H
#define _COMPAT_SYS_SENDFILE_H

#include <sys/types.h>
#include <errno.h>

static inline ssize_t sendfile(int out_fd, int in_fd, off_t *offset, size_t count) {
  (void)out_fd; (void)in_fd; (void)offset; (void)count;
  errno = EINVAL;
  return -1;
}
#define sendfile64 sendfile

#endif
