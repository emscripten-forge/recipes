/*
 * sys/epoll.h -- compatibility header for building OpenJDK with Emscripten.
 * There is no epoll in the browser; the functions fail with ENOSYS and the
 * JDK uses the poll(2)-based selector instead.
 */
#ifndef _COMPAT_SYS_EPOLL_H
#define _COMPAT_SYS_EPOLL_H

#include <stdint.h>
#include <errno.h>
#include <signal.h>

#define EPOLL_CLOEXEC 02000000
#define EPOLLIN      0x001
#define EPOLLPRI     0x002
#define EPOLLOUT     0x004
#define EPOLLRDNORM  0x040
#define EPOLLRDBAND  0x080
#define EPOLLWRNORM  0x100
#define EPOLLWRBAND  0x200
#define EPOLLMSG     0x400
#define EPOLLERR     0x008
#define EPOLLHUP     0x010
#define EPOLLRDHUP   0x2000
#define EPOLLONESHOT (1U << 30)
#define EPOLLET      (1U << 31)
#define EPOLL_CTL_ADD 1
#define EPOLL_CTL_DEL 2
#define EPOLL_CTL_MOD 3

typedef union epoll_data {
  void *ptr;
  int fd;
  uint32_t u32;
  uint64_t u64;
} epoll_data_t;

struct epoll_event {
  uint32_t events;
  epoll_data_t data;
};

static inline int epoll_create(int size) { (void)size; errno = ENOSYS; return -1; }
static inline int epoll_create1(int flags) { (void)flags; errno = ENOSYS; return -1; }
static inline int epoll_ctl(int epfd, int op, int fd, struct epoll_event *ev) {
  (void)epfd; (void)op; (void)fd; (void)ev; errno = ENOSYS; return -1;
}
static inline int epoll_wait(int epfd, struct epoll_event *ev, int max, int timeout) {
  (void)epfd; (void)ev; (void)max; (void)timeout; errno = ENOSYS; return -1;
}
static inline int epoll_pwait(int epfd, struct epoll_event *ev, int max, int timeout,
                              const sigset_t *mask) {
  (void)mask; return epoll_wait(epfd, ev, max, timeout);
}

#endif
