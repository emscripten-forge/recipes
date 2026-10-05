/*
 * wasm_misc.c -- C library functions used by the JDK that Emscripten does
 * not provide.  None of them has a meaningful implementation in a browser
 * tab; they fail the way the JDK expects from a restricted system.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <sched.h>
#include <signal.h>
#include <string.h>
#include <sys/sysinfo.h>
#include <sys/shm.h>
#include <sys/types.h>

/* System V shared memory (HotSpot large pages, MIT-SHM): not available. */
int shmget(key_t key, size_t size, int flags) {
  (void)key; (void)size; (void)flags;
  errno = ENOSYS;
  return -1;
}
void *shmat(int id, const void *addr, int flags) {
  (void)id; (void)addr; (void)flags;
  errno = ENOSYS;
  return (void *)-1;
}
int shmdt(const void *addr) { (void)addr; errno = EINVAL; return -1; }
int shmctl(int id, int cmd, struct shmid_ds *buf) {
  (void)id; (void)cmd; (void)buf;
  errno = EINVAL;
  return -1;
}

/* Memory statistics: report 1 GB of RAM (see os::Linux in HotSpot). */
int sysinfo(struct sysinfo *info) {
  memset(info, 0, sizeof *info);
  info->totalram = 1024UL * 1024 * 1024;
  info->freeram = info->totalram / 2;
  info->mem_unit = 1;
  info->procs = 1;
  return 0;
}

/* Signals are never delivered asynchronously. */
int sigsuspend(const sigset_t *mask) { (void)mask; errno = EINTR; return -1; }

int sched_getaffinity(pid_t pid, size_t size, cpu_set_t *set) {
  (void)pid;
  if (set && size) {
    memset(set, 0, size);
    ((unsigned char *)set)[0] = 1;   /* CPU 0 */
    return 0;
  }
  errno = EINVAL;
  return -1;
}
