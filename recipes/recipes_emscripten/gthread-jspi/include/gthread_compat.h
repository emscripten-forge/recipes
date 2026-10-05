/*
 * gthread_compat.h -- force-include this header (-include gthread_compat.h)
 * into code that uses POSIX threads so that its thread, lock and sleep calls
 * are routed to the cooperative green-thread runtime (see gthread.h).
 *
 * libc itself keeps its own (single-threaded) implementation; only the code
 * compiled with this header sees the green-thread versions.
 */
#ifndef GTHREAD_COMPAT_H
#define GTHREAD_COMPAT_H

#include "gthread.h"

#undef pthread_equal

#define pthread_create            gt_pthread_create
#define pthread_join              gt_pthread_join
#define pthread_detach            gt_pthread_detach
#define pthread_exit              gt_pthread_exit
#define pthread_self              gt_pthread_self
#define pthread_equal             gt_pthread_equal
#define pthread_once              gt_pthread_once
#define pthread_key_create        gt_pthread_key_create
#define pthread_key_delete        gt_pthread_key_delete
#define pthread_getspecific       gt_pthread_getspecific
#define pthread_setspecific       gt_pthread_setspecific
#define pthread_getattr_np        gt_pthread_getattr_np
#define pthread_kill              gt_pthread_kill
#define pthread_getcpuclockid     gt_pthread_getcpuclockid
#define pthread_setname_np        gt_pthread_setname_np
#define pthread_getname_np        gt_pthread_getname_np
#define pthread_cancel            gt_pthread_cancel

#define pthread_mutexattr_init       gt_pthread_mutexattr_init
#define pthread_mutexattr_destroy    gt_pthread_mutexattr_destroy
#define pthread_mutexattr_settype    gt_pthread_mutexattr_settype
#define pthread_mutexattr_gettype    gt_pthread_mutexattr_gettype
#define pthread_mutexattr_setpshared gt_pthread_mutexattr_setpshared
#define pthread_mutexattr_setprotocol gt_pthread_mutexattr_setprotocol
#define pthread_mutex_init        gt_pthread_mutex_init
#define pthread_mutex_destroy     gt_pthread_mutex_destroy
#define pthread_mutex_lock        gt_pthread_mutex_lock
#define pthread_mutex_trylock     gt_pthread_mutex_trylock
#define pthread_mutex_timedlock   gt_pthread_mutex_timedlock
#define pthread_mutex_unlock      gt_pthread_mutex_unlock

#define pthread_condattr_init     gt_pthread_condattr_init
#define pthread_condattr_destroy  gt_pthread_condattr_destroy
#define pthread_condattr_setclock gt_pthread_condattr_setclock
#define pthread_condattr_getclock gt_pthread_condattr_getclock
#define pthread_condattr_setpshared gt_pthread_condattr_setpshared
#define pthread_cond_init         gt_pthread_cond_init
#define pthread_cond_destroy      gt_pthread_cond_destroy
#define pthread_cond_wait         gt_pthread_cond_wait
#define pthread_cond_timedwait    gt_pthread_cond_timedwait
#define pthread_cond_signal       gt_pthread_cond_signal
#define pthread_cond_broadcast    gt_pthread_cond_broadcast

#define pthread_rwlock_init       gt_pthread_rwlock_init
#define pthread_rwlock_destroy    gt_pthread_rwlock_destroy
#define pthread_rwlock_rdlock     gt_pthread_rwlock_rdlock
#define pthread_rwlock_tryrdlock  gt_pthread_rwlock_tryrdlock
#define pthread_rwlock_wrlock     gt_pthread_rwlock_wrlock
#define pthread_rwlock_trywrlock  gt_pthread_rwlock_trywrlock
#define pthread_rwlock_unlock     gt_pthread_rwlock_unlock

#define pthread_spin_init         gt_pthread_spin_init
#define pthread_spin_destroy      gt_pthread_spin_destroy
#define pthread_spin_lock         gt_pthread_spin_lock
#define pthread_spin_trylock      gt_pthread_spin_trylock
#define pthread_spin_unlock       gt_pthread_spin_unlock

#define sem_init                  gt_sem_init
#define sem_destroy               gt_sem_destroy
#define sem_wait                  gt_sem_wait
#define sem_trywait               gt_sem_trywait
#define sem_timedwait             gt_sem_timedwait
#define sem_post                  gt_sem_post
#define sem_getvalue              gt_sem_getvalue

#define sleep                     gt_sleep
#define usleep                    gt_usleep
#define nanosleep                 gt_nanosleep
#define clock_nanosleep           gt_clock_nanosleep
#define sched_yield               gt_sched_yield
#define poll                      gt_poll

#endif /* GTHREAD_COMPAT_H */
