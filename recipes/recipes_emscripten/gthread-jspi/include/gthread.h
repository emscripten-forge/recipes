/*
 * gthread.h -- cooperative ("green") POSIX threads for single-threaded
 * Emscripten builds, implemented on top of JavaScript Promise Integration
 * (JSPI) stack switching.
 *
 * Every green thread runs on its own WebAssembly stack (a WebAssembly.promising
 * entry) and its own region of linear-memory C stack.  Only one thread runs at
 * a time; a thread gives up the CPU when it blocks (mutex/cond/semaphore/join/
 * sleep), yields, or when a long-running thread calls gt_maybe_yield() at a
 * safe point.  Because nothing is ever preempted, code that is correct under
 * real pthreads keeps working, and no SharedArrayBuffer / cross-origin
 * isolation is needed, and the main browser thread (DOM) stays reachable.
 *
 * Copyright (c) 2026 emscripten-forge contributors.  MIT License.
 */
#ifndef GTHREAD_H
#define GTHREAD_H

#include <pthread.h>
#include <semaphore.h>
#include <sched.h>
#include <time.h>
#include <poll.h>
#include <signal.h>
#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- pthread replacement API ------------------------------------------ */
int  gt_pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
int  gt_pthread_join(pthread_t, void **);
int  gt_pthread_detach(pthread_t);
_Noreturn void gt_pthread_exit(void *);
pthread_t gt_pthread_self(void);
int  gt_pthread_equal(pthread_t, pthread_t);
int  gt_pthread_once(pthread_once_t *, void (*)(void));
int  gt_pthread_key_create(pthread_key_t *, void (*)(void *));
int  gt_pthread_key_delete(pthread_key_t);
void *gt_pthread_getspecific(pthread_key_t);
int  gt_pthread_setspecific(pthread_key_t, const void *);
int  gt_pthread_getattr_np(pthread_t, pthread_attr_t *);
int  gt_pthread_kill(pthread_t, int);
int  gt_pthread_getcpuclockid(pthread_t, clockid_t *);
int  gt_pthread_setname_np(pthread_t, const char *);
int  gt_pthread_getname_np(pthread_t, char *, size_t);
int  gt_pthread_cancel(pthread_t);

int  gt_pthread_mutexattr_init(pthread_mutexattr_t *);
int  gt_pthread_mutexattr_destroy(pthread_mutexattr_t *);
int  gt_pthread_mutexattr_settype(pthread_mutexattr_t *, int);
int  gt_pthread_mutexattr_gettype(const pthread_mutexattr_t *, int *);
int  gt_pthread_mutexattr_setpshared(pthread_mutexattr_t *, int);
int  gt_pthread_mutexattr_setprotocol(pthread_mutexattr_t *, int);
int  gt_pthread_mutex_init(pthread_mutex_t *, const pthread_mutexattr_t *);
int  gt_pthread_mutex_destroy(pthread_mutex_t *);
int  gt_pthread_mutex_lock(pthread_mutex_t *);
int  gt_pthread_mutex_trylock(pthread_mutex_t *);
int  gt_pthread_mutex_timedlock(pthread_mutex_t *, const struct timespec *);
int  gt_pthread_mutex_unlock(pthread_mutex_t *);

int  gt_pthread_condattr_init(pthread_condattr_t *);
int  gt_pthread_condattr_destroy(pthread_condattr_t *);
int  gt_pthread_condattr_setclock(pthread_condattr_t *, clockid_t);
int  gt_pthread_condattr_getclock(const pthread_condattr_t *, clockid_t *);
int  gt_pthread_condattr_setpshared(pthread_condattr_t *, int);
int  gt_pthread_cond_init(pthread_cond_t *, const pthread_condattr_t *);
int  gt_pthread_cond_destroy(pthread_cond_t *);
int  gt_pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *);
int  gt_pthread_cond_timedwait(pthread_cond_t *, pthread_mutex_t *, const struct timespec *);
int  gt_pthread_cond_signal(pthread_cond_t *);
int  gt_pthread_cond_broadcast(pthread_cond_t *);

int  gt_pthread_rwlock_init(pthread_rwlock_t *, const pthread_rwlockattr_t *);
int  gt_pthread_rwlock_destroy(pthread_rwlock_t *);
int  gt_pthread_rwlock_rdlock(pthread_rwlock_t *);
int  gt_pthread_rwlock_tryrdlock(pthread_rwlock_t *);
int  gt_pthread_rwlock_wrlock(pthread_rwlock_t *);
int  gt_pthread_rwlock_trywrlock(pthread_rwlock_t *);
int  gt_pthread_rwlock_unlock(pthread_rwlock_t *);

int  gt_pthread_spin_init(pthread_spinlock_t *, int);
int  gt_pthread_spin_destroy(pthread_spinlock_t *);
int  gt_pthread_spin_lock(pthread_spinlock_t *);
int  gt_pthread_spin_trylock(pthread_spinlock_t *);
int  gt_pthread_spin_unlock(pthread_spinlock_t *);

int  gt_sem_init(sem_t *, int, unsigned);
int  gt_sem_destroy(sem_t *);
int  gt_sem_wait(sem_t *);
int  gt_sem_trywait(sem_t *);
int  gt_sem_timedwait(sem_t *, const struct timespec *);
int  gt_sem_post(sem_t *);
int  gt_sem_getvalue(sem_t *, int *);

unsigned gt_sleep(unsigned);
int  gt_usleep(useconds_t);
int  gt_nanosleep(const struct timespec *, struct timespec *);
int  gt_clock_nanosleep(clockid_t, int, const struct timespec *, struct timespec *);
int  gt_sched_yield(void);
int  gt_poll(struct pollfd *, nfds_t, int);

/* ---- green-thread specific API ---------------------------------------- */

/* Give other runnable threads (and the browser event loop) a turn. */
void gt_yield(void);
/* Cheap check; yields when the current time slice is used up. */
void gt_maybe_yield(void);
/* Counter for instrumented code: increment it on hot paths and call
 * gt_maybe_yield() (and reset it) when it passes a threshold. */
extern int gt_yield_counter;
/* Non-zero when the running thread's time slice is exhausted. */
int  gt_should_yield(void);
/* Stack bounds of the calling thread (C/shadow stack in linear memory). */
void gt_current_stack(void **base_high, size_t *size);
/* Number of live green threads. */
int  gt_thread_count(void);
/* Integer id of the calling thread (0 == initial thread). */
int  gt_current_id(void);

/*
 * I/O wait channels.  A thread can block until some external (JavaScript)
 * event arrives: gt_io_wait(ch, timeout_ms) blocks until gt_io_notify(ch) is
 * called (normally from a JS event handler through the exported function
 * gt_io_notify) or the timeout (-1 == forever) expires.  Returns 0 when
 * notified, ETIMEDOUT otherwise.  Channels are small integers < 64.
 */
int  gt_io_wait(int channel, int timeout_ms);
void gt_io_notify(int channel);
/* Register a poll() hook for a virtual file descriptor (use values from
 * GT_VIRTUAL_FD_BASE up).  gt_poll() asks the hook for readiness and blocks
 * on io_channel.  If a poll set mixes virtual and real descriptors, the
 * program must also notify io_channel when the real descriptors become
 * ready (e.g. after writing to a wake-up pipe). */
#define GT_VIRTUAL_FD_BASE 0x7ff00000
typedef int (*gt_poll_hook_t)(int fd, short events, short *revents);
void gt_register_poll_fd(int fd, gt_poll_hook_t hook, int io_channel);

#ifdef __cplusplus
}
#endif

#endif /* GTHREAD_H */
