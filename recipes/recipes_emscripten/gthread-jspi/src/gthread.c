/*
 * gthread.c -- cooperative POSIX threads for single-threaded Emscripten
 * builds using JSPI (JavaScript Promise Integration) stack switching.
 *
 * Design
 * ------
 *  - Each green thread owns a region of linear memory used as its C (shadow)
 *    stack and runs on its own WebAssembly stack, created by calling the
 *    WebAssembly.promising-wrapped export gt_thread_entry() from JavaScript.
 *  - A thread that must wait calls gt_block(), which records its C stack
 *    pointer and calls the suspending import gt_js_block().  That suspends its
 *    WebAssembly stack and hands control to the JavaScript dispatcher, which
 *    asks gt_pick_next() for the next runnable thread and resumes (or starts)
 *    it.  When a thread is resumed, the first thing it does is to restore its
 *    C stack pointer.
 *  - All scheduling state lives in C; JavaScript only owns the suspended
 *    stacks (promise resolvers) and the timers used when every thread sleeps.
 *
 * Copyright (c) 2026 emscripten-forge contributors.  MIT License.
 */
#include <errno.h>
#include <limits.h>
#include <setjmp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include <emscripten.h>
#include <emscripten/stack.h>

#include "gthread.h"

/* -------------------------------------------------------------------------
 * JavaScript side (gthread_lib.js)
 * ---------------------------------------------------------------------- */
extern void gt_js_block(int id);                       /* suspending */
extern void gt_js_thread_created(int id, uintptr_t stack_top);
extern void gt_js_kick(void);
extern void _emscripten_stack_restore(uintptr_t sp);

#define GT_DEFAULT_STACK   (512 * 1024)
#define GT_MIN_STACK       (64 * 1024)
#define GT_KEYS_MAX        256
#define GT_IO_CHANNELS     64
#define GT_MAX_POLL_FDS    16

enum { GT_RUNNABLE = 1, GT_BLOCKED = 2, GT_EXITED = 3 };

typedef struct gthread gthread;
typedef struct gt_queue { gthread *head, *tail; } gt_queue;

struct gthread {
  int id;
  int state;
  int detached;
  int joined;
  int started;               /* has run at least once */
  int timed_out;             /* set when a timed wait expired */
  int saved_errno;
  uintptr_t saved_sp;
  char *stack_mem;           /* malloc'ed C stack (NULL for main) */
  uintptr_t stack_low, stack_high;
  void *(*start)(void *);
  void *arg;
  void *retval;
  gthread *joiner;
  gthread *rnext;            /* run queue link */
  gthread *wnext;            /* wait queue link */
  gt_queue *waitq;           /* queue we are waiting in (NULL if none) */
  double deadline;           /* ms (emscripten_get_now), < 0 == none */
  gthread *tnext;            /* timed-wait list link */
  gthread *anext;            /* all-threads list link */
  jmp_buf exit_jmp;
  void *spec[GT_KEYS_MAX];
  char name[32];
};

static gthread gt_main_thread;
static gthread *gt_cur;
static gthread *gt_all;
static gt_queue gt_runq;
static gthread *gt_timed;          /* threads with a deadline */
static gthread *gt_zombies;        /* exited threads whose stack can be freed */
static int gt_next_id = 1;
static int gt_live = 1;
static int gt_inited;
static double gt_slice_start;
static double gt_idle_delay = -1;  /* for the JS dispatcher */
static double gt_slice_ms = 12.0;
/* Incremented by instrumented code (e.g. interpreters) between calls to
 * gt_maybe_yield(), so that the clock is not queried on every check. */
int gt_yield_counter;

/* ---- helpers ---------------------------------------------------------- */

static void gt_init(void) {
  if (gt_inited) return;
  gt_inited = 1;
  gthread *m = &gt_main_thread;
  memset(m, 0, sizeof(*m));
  m->id = 0;
  m->state = GT_RUNNABLE;
  m->started = 1;
  m->deadline = -1;
  m->stack_high = emscripten_stack_get_base();
  m->stack_low = emscripten_stack_get_end();
  strcpy(m->name, "main");
  gt_all = m;
  gt_cur = m;
  gt_slice_start = emscripten_get_now();
}

static inline gthread *gt_self(void) {
  if (!gt_inited) gt_init();
  return gt_cur;
}

static void q_push(gt_queue *q, gthread *t) {
  t->wnext = NULL;
  if (q->tail) q->tail->wnext = t; else q->head = t;
  q->tail = t;
  t->waitq = q;
}

static gthread *q_pop(gt_queue *q) {
  gthread *t = q->head;
  if (t) {
    q->head = t->wnext;
    if (!q->head) q->tail = NULL;
    t->wnext = NULL;
    t->waitq = NULL;
  }
  return t;
}

static void q_remove(gt_queue *q, gthread *t) {
  gthread *prev = NULL, *p = q->head;
  while (p && p != t) { prev = p; p = p->wnext; }
  if (!p) return;
  if (prev) prev->wnext = p->wnext; else q->head = p->wnext;
  if (q->tail == p) q->tail = prev;
  p->wnext = NULL;
  p->waitq = NULL;
}

static void timed_remove(gthread *t) {
  gthread **pp = &gt_timed;
  while (*pp) {
    if (*pp == t) { *pp = t->tnext; t->tnext = NULL; return; }
    pp = &(*pp)->tnext;
  }
}

static void runq_push(gthread *t) {
  t->rnext = NULL;
  if (gt_runq.tail) gt_runq.tail->rnext = t; else gt_runq.head = t;
  gt_runq.tail = t;
}

static gthread *runq_pop(void) {
  gthread *t = gt_runq.head;
  if (t) {
    gt_runq.head = t->rnext;
    if (!gt_runq.head) gt_runq.tail = NULL;
    t->rnext = NULL;
  }
  return t;
}

/* Make a blocked thread runnable (removing it from any wait structures). */
static void gt_wake(gthread *t) {
  if (t->state != GT_BLOCKED) return;
  if (t->waitq) q_remove(t->waitq, t);
  if (t->deadline >= 0) { timed_remove(t); t->deadline = -1; }
  t->state = GT_RUNNABLE;
  runq_push(t);
}

static gthread *gt_find(int id) {
  for (gthread *t = gt_all; t; t = t->anext)
    if (t->id == id) return t;
  return NULL;
}

/*
 * Give up the CPU.  The caller has already either queued itself on the run
 * queue (yield) or marked itself blocked (and put itself into a wait queue
 * and/or the timed list).  Returns when the thread is scheduled again.
 */
static void gt_block(void) {
  gthread *self = gt_cur;
  self->saved_errno = errno;
  self->saved_sp = emscripten_stack_get_current();
  gt_js_block(self->id);
  /* Resumed: restore our C stack pointer before calling anything else. */
  _emscripten_stack_restore(self->saved_sp);
  gt_cur = self;
  errno = self->saved_errno;
}

/* Current time on the monotonic clock in ms. */
static inline double now_ms(void) { return emscripten_get_now(); }

static double abstime_to_deadline(const struct timespec *ts, clockid_t clk) {
  if (!ts) return -1;
  double target = (double)ts->tv_sec * 1000.0 + (double)ts->tv_nsec / 1.0e6;
  struct timespec cur;
  clock_gettime(clk, &cur);
  double curms = (double)cur.tv_sec * 1000.0 + (double)cur.tv_nsec / 1.0e6;
  double delta = target - curms;
  if (delta < 0) delta = 0;
  return now_ms() + delta;
}

/*
 * Block the current thread on queue q (may be NULL) until woken or until the
 * deadline (ms, < 0 == none).  Returns 0 or ETIMEDOUT.
 */
static int gt_wait(gt_queue *q, double deadline) {
  gthread *self = gt_self();
  self->state = GT_BLOCKED;
  self->timed_out = 0;
  if (q) q_push(q, self);
  self->deadline = deadline;
  if (deadline >= 0) { self->tnext = gt_timed; gt_timed = self; }
  gt_block();
  return self->timed_out ? ETIMEDOUT : 0;
}

/* ---- exported to the JS dispatcher ------------------------------------- */

EMSCRIPTEN_KEEPALIVE int gt_pick_next(void) {
  if (!gt_inited) gt_init();
  /* Free stacks of threads that have fully exited. */
  while (gt_zombies) {
    gthread *z = gt_zombies;
    gt_zombies = z->tnext;
    free(z->stack_mem);
    z->stack_mem = NULL;
    if (z->detached || z->joined) free(z);
  }
  double now = now_ms();
  double next = -1;
  for (gthread *t = gt_timed; t; ) {
    gthread *n = t->tnext;
    if (t->deadline <= now) {
      t->timed_out = 1;
      gt_wake(t);
    } else if (next < 0 || t->deadline < next) {
      next = t->deadline;
    }
    t = n;
  }
  gthread *t = runq_pop();
  if (!t) {
    gt_idle_delay = next < 0 ? -1 : (next - now);
    return -1;
  }
  gt_cur = t;
  gt_slice_start = now;
  t->started = 1;
  return t->id;
}

EMSCRIPTEN_KEEPALIVE double gt_get_idle_delay(void) { return gt_idle_delay; }

EMSCRIPTEN_KEEPALIVE void gt_thread_entry(int id) {
  gthread *t = gt_find(id);
  if (!t) abort();
  gt_cur = t;
  if (setjmp(t->exit_jmp) == 0) {
    t->retval = t->start(t->arg);
  }
  /* thread-specific data destructors */
  extern void gt_run_key_destructors(gthread *);
  gt_run_key_destructors(t);
  t->state = GT_EXITED;
  gt_live--;
  if (t->joiner) gt_wake(t->joiner);
  /* unlink from all-threads list */
  for (gthread **pp = &gt_all; *pp; pp = &(*pp)->anext)
    if (*pp == t) { *pp = t->anext; break; }
  t->tnext = gt_zombies;
  gt_zombies = t;
  /* returning resolves the promise of this stack; the dispatcher continues */
}

/* ---- threads ----------------------------------------------------------- */

int gt_pthread_create(pthread_t *out, const pthread_attr_t *attr,
                      void *(*start)(void *), void *arg) {
  gt_self();
  size_t ss = GT_DEFAULT_STACK;
  int detach = 0;
  if (attr) {
    size_t s = 0;
    if (pthread_attr_getstacksize(attr, &s) == 0 && s) ss = s;
    int ds = 0;
    if (pthread_attr_getdetachstate(attr, &ds) == 0)
      detach = (ds == PTHREAD_CREATE_DETACHED);
  }
  if (ss < GT_MIN_STACK) ss = GT_MIN_STACK;
  ss = (ss + 15) & ~(size_t)15;
  gthread *t = (gthread *)calloc(1, sizeof(gthread));
  if (!t) return EAGAIN;
  t->stack_mem = (char *)aligned_alloc(16, ss);
  if (!t->stack_mem) { free(t); return EAGAIN; }
  t->id = gt_next_id++;
  t->stack_low = (uintptr_t)t->stack_mem;
  t->stack_high = (uintptr_t)t->stack_mem + ss;
  t->start = start;
  t->arg = arg;
  t->detached = detach;
  t->deadline = -1;
  snprintf(t->name, sizeof t->name, "thread-%d", t->id);
  t->anext = gt_all;
  gt_all = t;
  gt_live++;
  gt_js_thread_created(t->id, t->stack_high);
  t->state = GT_RUNNABLE;
  runq_push(t);
  *out = (pthread_t)t;
  return 0;
}

int gt_pthread_join(pthread_t th, void **ret) {
  gthread *self = gt_self();
  gthread *t = (gthread *)th;
  if (!t || t == self) return EDEADLK;
  if (t->detached) return EINVAL;
  while (t->state != GT_EXITED) {
    t->joiner = self;
    gt_wait(NULL, -1);
  }
  if (ret) *ret = t->retval;
  t->joined = 1;
  if (!t->stack_mem) free(t);   /* stack already released: free now */
  return 0;
}

int gt_pthread_detach(pthread_t th) {
  gthread *t = (gthread *)th;
  if (!t) return ESRCH;
  t->detached = 1;
  if (t->state == GT_EXITED && !t->stack_mem) free(t);
  return 0;
}

_Noreturn void gt_pthread_exit(void *v) {
  gthread *self = gt_self();
  if (self == &gt_main_thread) {
    /* Main thread exit: wait for all others, then exit the process. */
    while (gt_live > 1) gt_usleep(10000);
    exit(0);
  }
  self->retval = v;
  longjmp(self->exit_jmp, 1);
}

pthread_t gt_pthread_self(void) { return (pthread_t)gt_self(); }
int gt_pthread_equal(pthread_t a, pthread_t b) { return a == b; }
int gt_current_id(void) { return gt_self()->id; }
int gt_thread_count(void) { return gt_live; }

int gt_pthread_once(pthread_once_t *o, void (*fn)(void)) {
  /* 0 = not started, 1 = running, 2 = done */
  while (*o == 1) gt_yield();
  if (*o == 2) return 0;
  *o = 1;
  fn();
  *o = 2;
  return 0;
}

int gt_pthread_getattr_np(pthread_t th, pthread_attr_t *a) {
  gthread *t = (gthread *)th;
  if (!t) t = gt_self();
  pthread_attr_init(a);
  size_t size = t->stack_high - t->stack_low;
  pthread_attr_setstack(a, (void *)t->stack_low, size);
  pthread_attr_setguardsize(a, 0);
  return 0;
}

void gt_current_stack(void **base_high, size_t *size) {
  gthread *t = gt_self();
  if (base_high) *base_high = (void *)t->stack_high;
  if (size) *size = t->stack_high - t->stack_low;
}

int gt_pthread_kill(pthread_t th, int sig) {
  (void)th;
  if (sig == 0) return 0;
  return ESRCH;   /* asynchronous signals are not supported */
}

int gt_pthread_getcpuclockid(pthread_t th, clockid_t *clk) {
  (void)th;
  *clk = CLOCK_MONOTONIC;
  return 0;
}

int gt_pthread_setname_np(pthread_t th, const char *name) {
  gthread *t = (gthread *)th;
  if (!t) return ESRCH;
  snprintf(t->name, sizeof t->name, "%s", name);
  return 0;
}

int gt_pthread_getname_np(pthread_t th, char *buf, size_t len) {
  gthread *t = (gthread *)th;
  if (!t) return ESRCH;
  snprintf(buf, len, "%s", t->name);
  return 0;
}

int gt_pthread_cancel(pthread_t th) { (void)th; return ENOSYS; }

/* ---- thread-specific data --------------------------------------------- */

static struct { int used; void (*dtor)(void *); } gt_keys[GT_KEYS_MAX];

int gt_pthread_key_create(pthread_key_t *k, void (*dtor)(void *)) {
  for (unsigned i = 0; i < GT_KEYS_MAX; i++) {
    if (!gt_keys[i].used) {
      gt_keys[i].used = 1;
      gt_keys[i].dtor = dtor;
      for (gthread *t = gt_all; t; t = t->anext) t->spec[i] = NULL;
      *k = i;
      return 0;
    }
  }
  return EAGAIN;
}

int gt_pthread_key_delete(pthread_key_t k) {
  if (k >= GT_KEYS_MAX || !gt_keys[k].used) return EINVAL;
  gt_keys[k].used = 0;
  gt_keys[k].dtor = NULL;
  return 0;
}

void *gt_pthread_getspecific(pthread_key_t k) {
  if (k >= GT_KEYS_MAX) return NULL;
  return gt_self()->spec[k];
}

int gt_pthread_setspecific(pthread_key_t k, const void *v) {
  if (k >= GT_KEYS_MAX || !gt_keys[k].used) return EINVAL;
  gt_self()->spec[k] = (void *)v;
  return 0;
}

void gt_run_key_destructors(gthread *t) {
  for (int iter = 0; iter < 4; iter++) {
    int any = 0;
    for (unsigned i = 0; i < GT_KEYS_MAX; i++) {
      if (gt_keys[i].used && gt_keys[i].dtor && t->spec[i]) {
        void *v = t->spec[i];
        t->spec[i] = NULL;
        gt_keys[i].dtor(v);
        any = 1;
      }
    }
    if (!any) break;
  }
}

/* ---- mutexes ------------------------------------------------------------ */

typedef struct {
  int type;               /* overlaps musl _m_type; 0 == normal */
  gthread *owner;
  int count;
  gt_queue q;
  int unused;
} gt_mutex;
_Static_assert(sizeof(gt_mutex) <= sizeof(pthread_mutex_t), "mutex size");

int gt_pthread_mutexattr_init(pthread_mutexattr_t *a) { a->__attr = 0; return 0; }
int gt_pthread_mutexattr_destroy(pthread_mutexattr_t *a) { (void)a; return 0; }
int gt_pthread_mutexattr_settype(pthread_mutexattr_t *a, int type) {
  if ((unsigned)type > 2) return EINVAL;
  a->__attr = (a->__attr & ~3u) | (unsigned)type;
  return 0;
}
int gt_pthread_mutexattr_gettype(const pthread_mutexattr_t *a, int *type) {
  *type = a->__attr & 3;
  return 0;
}
int gt_pthread_mutexattr_setpshared(pthread_mutexattr_t *a, int p) { (void)a; (void)p; return 0; }
int gt_pthread_mutexattr_setprotocol(pthread_mutexattr_t *a, int p) { (void)a; (void)p; return 0; }

int gt_pthread_mutex_init(pthread_mutex_t *mm, const pthread_mutexattr_t *a) {
  gt_mutex *m = (gt_mutex *)mm;
  memset(mm, 0, sizeof(*mm));
  m->type = a ? (int)(a->__attr & 3) : PTHREAD_MUTEX_DEFAULT;
  return 0;
}

int gt_pthread_mutex_destroy(pthread_mutex_t *mm) { (void)mm; return 0; }

static int mutex_lock(gt_mutex *m, double deadline, int try_only) {
  gthread *self = gt_self();
  if (m->owner == self) {
    if (m->type == PTHREAD_MUTEX_RECURSIVE) {
      if (m->count == INT_MAX) return EAGAIN;
      m->count++;
      return 0;
    }
    if (m->type == PTHREAD_MUTEX_ERRORCHECK) return EDEADLK;
    if (try_only) return EBUSY;
    /* normal mutex relocked by its owner: real deadlock */
  }
  while (m->owner) {
    if (try_only) return EBUSY;
    if (gt_wait(&m->q, deadline) == ETIMEDOUT && m->owner) return ETIMEDOUT;
  }
  m->owner = self;
  m->count = 1;
  return 0;
}

int gt_pthread_mutex_lock(pthread_mutex_t *mm) { return mutex_lock((gt_mutex *)mm, -1, 0); }
int gt_pthread_mutex_trylock(pthread_mutex_t *mm) { return mutex_lock((gt_mutex *)mm, -1, 1); }
int gt_pthread_mutex_timedlock(pthread_mutex_t *mm, const struct timespec *ts) {
  return mutex_lock((gt_mutex *)mm, abstime_to_deadline(ts, CLOCK_REALTIME), 0);
}

int gt_pthread_mutex_unlock(pthread_mutex_t *mm) {
  gt_mutex *m = (gt_mutex *)mm;
  gthread *self = gt_self();
  if (m->owner != self) {
    if (m->type == PTHREAD_MUTEX_ERRORCHECK || m->type == PTHREAD_MUTEX_RECURSIVE)
      return EPERM;
    if (!m->owner) return 0;
  }
  if (--m->count > 0) return 0;
  m->owner = NULL;
  m->count = 0;
  gthread *w = q_pop(&m->q);
  if (w) gt_wake(w);
  return 0;
}

/* ---- condition variables ------------------------------------------------ */

typedef struct { int clock; gt_queue q; } gt_cond;
_Static_assert(sizeof(gt_cond) <= sizeof(pthread_cond_t), "cond size");

int gt_pthread_condattr_init(pthread_condattr_t *a) { a->__attr = CLOCK_REALTIME; return 0; }
int gt_pthread_condattr_destroy(pthread_condattr_t *a) { (void)a; return 0; }
int gt_pthread_condattr_setclock(pthread_condattr_t *a, clockid_t c) { a->__attr = (unsigned)c; return 0; }
int gt_pthread_condattr_getclock(const pthread_condattr_t *a, clockid_t *c) { *c = (clockid_t)a->__attr; return 0; }
int gt_pthread_condattr_setpshared(pthread_condattr_t *a, int p) { (void)a; (void)p; return 0; }

int gt_pthread_cond_init(pthread_cond_t *cc, const pthread_condattr_t *a) {
  gt_cond *c = (gt_cond *)cc;
  memset(cc, 0, sizeof(*cc));
  c->clock = a ? (int)a->__attr : CLOCK_REALTIME;
  return 0;
}

int gt_pthread_cond_destroy(pthread_cond_t *cc) { (void)cc; return 0; }

static int cond_wait(gt_cond *c, gt_mutex *m, double deadline) {
  gthread *self = gt_self();
  if (m->owner != self) return EPERM;
  int count = m->count;
  /* release the mutex completely */
  m->count = 1;
  gt_pthread_mutex_unlock((pthread_mutex_t *)m);
  int r = gt_wait(&c->q, deadline);
  mutex_lock(m, -1, 0);
  m->count = count;
  return r;
}

int gt_pthread_cond_wait(pthread_cond_t *cc, pthread_mutex_t *mm) {
  return cond_wait((gt_cond *)cc, (gt_mutex *)mm, -1);
}

int gt_pthread_cond_timedwait(pthread_cond_t *cc, pthread_mutex_t *mm,
                              const struct timespec *ts) {
  gt_cond *c = (gt_cond *)cc;
  return cond_wait(c, (gt_mutex *)mm, abstime_to_deadline(ts, c->clock));
}

int gt_pthread_cond_signal(pthread_cond_t *cc) {
  gthread *w = q_pop(&((gt_cond *)cc)->q);
  if (w) gt_wake(w);
  return 0;
}

int gt_pthread_cond_broadcast(pthread_cond_t *cc) {
  gthread *w;
  while ((w = q_pop(&((gt_cond *)cc)->q))) gt_wake(w);
  return 0;
}

/* ---- rwlocks ---------------------------------------------------------- */

typedef struct { int readers; gthread *writer; gt_queue rq; gt_queue wq; } gt_rwlock;
_Static_assert(sizeof(gt_rwlock) <= sizeof(pthread_rwlock_t), "rwlock size");

int gt_pthread_rwlock_init(pthread_rwlock_t *l, const pthread_rwlockattr_t *a) {
  (void)a; memset(l, 0, sizeof(*l)); return 0;
}
int gt_pthread_rwlock_destroy(pthread_rwlock_t *l) { (void)l; return 0; }
int gt_pthread_rwlock_rdlock(pthread_rwlock_t *ll) {
  gt_rwlock *l = (gt_rwlock *)ll;
  while (l->writer || l->wq.head) gt_wait(&l->rq, -1);
  l->readers++;
  return 0;
}
int gt_pthread_rwlock_tryrdlock(pthread_rwlock_t *ll) {
  gt_rwlock *l = (gt_rwlock *)ll;
  if (l->writer) return EBUSY;
  l->readers++;
  return 0;
}
int gt_pthread_rwlock_wrlock(pthread_rwlock_t *ll) {
  gt_rwlock *l = (gt_rwlock *)ll;
  while (l->writer || l->readers) gt_wait(&l->wq, -1);
  l->writer = gt_self();
  return 0;
}
int gt_pthread_rwlock_trywrlock(pthread_rwlock_t *ll) {
  gt_rwlock *l = (gt_rwlock *)ll;
  if (l->writer || l->readers) return EBUSY;
  l->writer = gt_self();
  return 0;
}
int gt_pthread_rwlock_unlock(pthread_rwlock_t *ll) {
  gt_rwlock *l = (gt_rwlock *)ll;
  gthread *w;
  if (l->writer == gt_self()) l->writer = NULL;
  else if (l->readers > 0) l->readers--;
  if (!l->writer && !l->readers && (w = q_pop(&l->wq))) { gt_wake(w); return 0; }
  if (!l->writer && !l->wq.head)
    while ((w = q_pop(&l->rq))) gt_wake(w);
  return 0;
}

/* ---- spinlocks: never spin, yield instead ------------------------------ */

int gt_pthread_spin_init(pthread_spinlock_t *s, int p) { (void)p; *s = 0; return 0; }
int gt_pthread_spin_destroy(pthread_spinlock_t *s) { (void)s; return 0; }
int gt_pthread_spin_lock(pthread_spinlock_t *s) { while (*s) gt_yield(); *s = 1; return 0; }
int gt_pthread_spin_trylock(pthread_spinlock_t *s) { if (*s) return EBUSY; *s = 1; return 0; }
int gt_pthread_spin_unlock(pthread_spinlock_t *s) { *s = 0; return 0; }

/* ---- semaphores -------------------------------------------------------- */

typedef struct { int count; gt_queue q; } gt_sem;
_Static_assert(sizeof(gt_sem) <= sizeof(sem_t), "sem size");

int gt_sem_init(sem_t *ss, int pshared, unsigned v) {
  (void)pshared;
  if (v > SEM_VALUE_MAX) { errno = EINVAL; return -1; }
  memset(ss, 0, sizeof(*ss));
  ((gt_sem *)ss)->count = (int)v;
  return 0;
}
int gt_sem_destroy(sem_t *ss) { (void)ss; return 0; }

static int sem_wait_until(gt_sem *s, double deadline, int try_only) {
  while (s->count <= 0) {
    if (try_only) { errno = EAGAIN; return -1; }
    if (gt_wait(&s->q, deadline) == ETIMEDOUT && s->count <= 0) {
      errno = ETIMEDOUT;
      return -1;
    }
  }
  s->count--;
  return 0;
}

int gt_sem_wait(sem_t *ss) { return sem_wait_until((gt_sem *)ss, -1, 0); }
int gt_sem_trywait(sem_t *ss) { return sem_wait_until((gt_sem *)ss, -1, 1); }
int gt_sem_timedwait(sem_t *ss, const struct timespec *ts) {
  return sem_wait_until((gt_sem *)ss, abstime_to_deadline(ts, CLOCK_REALTIME), 0);
}
int gt_sem_post(sem_t *ss) {
  gt_sem *s = (gt_sem *)ss;
  if (s->count == SEM_VALUE_MAX) { errno = EOVERFLOW; return -1; }
  s->count++;
  gthread *w = q_pop(&s->q);
  if (w) gt_wake(w);
  return 0;
}
int gt_sem_getvalue(sem_t *ss, int *v) { *v = ((gt_sem *)ss)->count; return 0; }

/* ---- sleeping and yielding --------------------------------------------- */

void gt_yield(void) {
  gthread *self = gt_self();
  self->state = GT_RUNNABLE;
  runq_push(self);
  gt_block();
}

int gt_should_yield(void) {
  return (now_ms() - gt_slice_start) >= gt_slice_ms;
}

void gt_maybe_yield(void) {
  if (gt_should_yield()) gt_yield();
}

static void sleep_ms(double ms) {
  if (ms <= 0) { gt_yield(); return; }
  gt_wait(NULL, now_ms() + ms);
}

int gt_sched_yield(void) { gt_yield(); return 0; }

unsigned gt_sleep(unsigned s) { sleep_ms(s * 1000.0); return 0; }

int gt_usleep(useconds_t us) { sleep_ms(us / 1000.0); return 0; }

int gt_nanosleep(const struct timespec *req, struct timespec *rem) {
  if (!req || req->tv_nsec < 0 || req->tv_nsec >= 1000000000L) {
    errno = EINVAL;
    return -1;
  }
  sleep_ms((double)req->tv_sec * 1000.0 + req->tv_nsec / 1.0e6);
  if (rem) { rem->tv_sec = 0; rem->tv_nsec = 0; }
  return 0;
}

int gt_clock_nanosleep(clockid_t clk, int flags, const struct timespec *req,
                       struct timespec *rem) {
  if (flags & TIMER_ABSTIME) {
    double d = abstime_to_deadline(req, clk);
    gt_wait(NULL, d);
    return 0;
  }
  return gt_nanosleep(req, rem) == 0 ? 0 : errno;
}

/* ---- I/O channels ---------------------------------------------------- */

static struct { int pending; gt_queue q; } gt_io[GT_IO_CHANNELS];

int gt_io_wait(int ch, int timeout_ms) {
  if (ch < 0 || ch >= GT_IO_CHANNELS) return EINVAL;
  if (gt_io[ch].pending) { gt_io[ch].pending = 0; return 0; }
  int r = gt_wait(&gt_io[ch].q, timeout_ms < 0 ? -1 : now_ms() + timeout_ms);
  if (r == 0) gt_io[ch].pending = 0;
  return r;
}

EMSCRIPTEN_KEEPALIVE void gt_io_notify(int ch) {
  if (ch < 0 || ch >= GT_IO_CHANNELS) return;
  if (!gt_inited) gt_init();
  gt_io[ch].pending = 1;
  gthread *w;
  int woke = 0;
  while ((w = q_pop(&gt_io[ch].q))) { gt_wake(w); woke = 1; }
  if (woke) gt_js_kick();
}

static struct { int fd; gt_poll_hook_t hook; int channel; } gt_vfds[GT_MAX_POLL_FDS];

void gt_register_poll_fd(int fd, gt_poll_hook_t hook, int channel) {
  for (int i = 0; i < GT_MAX_POLL_FDS; i++) {
    if (gt_vfds[i].hook == NULL || gt_vfds[i].fd == fd) {
      gt_vfds[i].fd = fd;
      gt_vfds[i].hook = hook;
      gt_vfds[i].channel = channel;
      return;
    }
  }
}

static int vfd_index(int fd) {
  for (int i = 0; i < GT_MAX_POLL_FDS; i++)
    if (gt_vfds[i].hook && gt_vfds[i].fd == fd) return i;
  return -1;
}

#undef poll
int gt_poll(struct pollfd *fds, nfds_t n, int timeout) {
  double deadline = timeout < 0 ? -1 : now_ms() + timeout;
  for (;;) {
    int ready = 0, have_real = 0, chan = -1;
    for (nfds_t i = 0; i < n; i++) {
      fds[i].revents = 0;
      if (fds[i].fd < 0) continue;
      int vi = vfd_index(fds[i].fd);
      if (vi >= 0) {
        short rev = 0;
        gt_vfds[vi].hook(fds[i].fd, fds[i].events, &rev);
        fds[i].revents = rev;
        if (rev) ready++;
        if (chan < 0) chan = gt_vfds[vi].channel;
      } else {
        struct pollfd one = fds[i];
        int r = poll(&one, 1, 0);
        if (r > 0) { fds[i].revents = one.revents; ready++; }
        have_real = 1;
      }
    }
    if (ready || timeout == 0) return ready;
    double now = now_ms();
    if (deadline >= 0 && now >= deadline) return 0;
    /* Wait for an I/O notification.  When a virtual fd is part of the set,
     * its channel is also notified for activity on the real fds (see
     * gt_register_poll_fd); otherwise real fds (pipes) are re-polled often. */
    double wait = deadline < 0 ? 1e9 : deadline - now;
    if (have_real && chan < 0 && wait > 10) wait = 10;
    if (chan >= 0) gt_io_wait(chan, (int)(wait + 0.999));
    else sleep_ms(wait);
  }
}

/* ---- diagnostics -------------------------------------------------------- */

/* Prints the state of all green threads to stderr (callable from JS as
 * Module._gt_debug_dump()). */
EMSCRIPTEN_KEEPALIVE void gt_debug_dump(void) {
  static const char *names[] = { "?", "runnable", "blocked", "exited" };
  double now = now_ms();
  fprintf(stderr, "gthread: %d live, current %d\n", gt_live, gt_cur ? gt_cur->id : -1);
  for (gthread *t = gt_all; t; t = t->anext) {
    fprintf(stderr, "  [%d] %-24s %-8s%s", t->id, t->name,
            names[t->state > 3 ? 0 : t->state], t->waitq ? " (wait queue)" : "");
    if (t->deadline >= 0) fprintf(stderr, " timeout in %.0f ms", t->deadline - now);
    fprintf(stderr, "\n");
  }
}
