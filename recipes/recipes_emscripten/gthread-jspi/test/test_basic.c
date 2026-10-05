#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <alloca.h>
#include <errno.h>
#include <time.h>
#include <emscripten.h>

static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cv = PTHREAD_COND_INITIALIZER;
static int queue[16], qn = 0, produced = 0, consumed = 0;
static pthread_key_t key;
static sem_t sem;

static int recurse(int depth, int tag) {
  volatile char *buf = alloca(256);
  memset((char *)buf, tag, 256);
  int r = 0;
  if (depth > 0) {
    if (depth % 50 == 0) sched_yield();       /* switch mid-recursion */
    r = recurse(depth - 1, tag);
  }
  for (int i = 0; i < 256; i++)
    if (buf[i] != (char)tag) { printf("STACK CORRUPTION tag %d\n", tag); abort(); }
  return r + 1;
}

static void *producer(void *arg) {
  int id = (int)(long)arg;
  pthread_setspecific(key, (void *)(long)(100 + id));
  for (int i = 0; i < 200; i++) {
    pthread_mutex_lock(&mu);
    while (qn == 16) pthread_cond_wait(&cv, &mu);
    queue[qn++] = i;
    produced++;
    pthread_cond_broadcast(&cv);
    pthread_mutex_unlock(&mu);
    if (i % 37 == 0) usleep(1000);
  }
  if ((long)pthread_getspecific(key) != 100 + id) { printf("TLS BROKEN\n"); abort(); }
  int d = recurse(300, id + 1);
  return (void *)(long)d;
}

static void *consumer(void *arg) {
  (void)arg;
  for (;;) {
    pthread_mutex_lock(&mu);
    while (qn == 0 && consumed < 600) {
      struct timespec ts;
      clock_gettime(CLOCK_REALTIME, &ts);
      ts.tv_nsec += 5000000;
      if (ts.tv_nsec >= 1000000000) { ts.tv_sec++; ts.tv_nsec -= 1000000000; }
      pthread_cond_timedwait(&cv, &mu, &ts);
    }
    if (consumed >= 600) { pthread_mutex_unlock(&mu); break; }
    qn--;
    consumed++;
    pthread_cond_broadcast(&cv);
    pthread_mutex_unlock(&mu);
  }
  sem_post(&sem);
  return NULL;
}

static void *spinner(void *arg) {
  /* busy thread: must not starve others thanks to time slicing */
  double t0 = emscripten_get_now();
  volatile long x = 0;
  while (emscripten_get_now() - t0 < 300) { x++; if ((x & 1023) == 0) gt_maybe_yield(); }
  return arg;
}

int main(void) {
  pthread_key_create(&key, NULL);
  sem_init(&sem, 0, 0);
  pthread_t p[3], c, s;
  double t0 = emscripten_get_now();
  pthread_create(&s, NULL, spinner, NULL);
  for (int i = 0; i < 3; i++) pthread_create(&p[i], NULL, producer, (void *)(long)i);
  pthread_create(&c, NULL, consumer, NULL);
  for (int i = 0; i < 3; i++) {
    void *r;
    pthread_join(p[i], &r);
    printf("producer %d done, recursion depth %ld\n", i, (long)r);
  }
  sem_wait(&sem);
  pthread_join(c, NULL);
  pthread_join(s, NULL);
  printf("produced=%d consumed=%d threads=%d elapsed=%.0fms\n", produced, consumed,
         gt_thread_count(), emscripten_get_now() - t0);
  struct timespec ts = {0, 50 * 1000000};
  double a = emscripten_get_now();
  nanosleep(&ts, NULL);
  printf("slept %.0f ms\n", emscripten_get_now() - a);
  printf("GTHREAD TEST OK\n");
  return 0;
}
