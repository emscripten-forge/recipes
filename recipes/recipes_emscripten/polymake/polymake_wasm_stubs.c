/* Emscripten stubs for POSIX APIs that libSingular.a references but that
 * emscripten's libc does not implement.
 *
 * libSingular.a(semaphore.o) calls the POSIX *named* semaphore functions, which
 * coordinate separate processes.  A wasm module is a single process with no
 * fork(), so there is nothing for them to coordinate and emscripten declares
 * them in <semaphore.h> without providing an implementation -- linking
 * libSingular then fails with "undefined symbol: sem_open".
 *
 * The Singular package solves this for its own executable with an equivalent
 * file, but compiles it only into that binary, so it is not available to anything
 * else that links libSingular.a.  These stubs are the same idea, kept on
 * polymake's side so that the singular package needs no change: pretend the
 * semaphore opened and report one free resource, which makes Singular's parallel
 * paths run as a single worker instead of failing.
 *
 * The pthread affinity calls are stubbed for the same reason: they exist only in
 * glibc, and any code asking about CPU affinity in a single-threaded wasm module
 * can be told "fine, nothing to do".
 */

#include <semaphore.h>
#include <stddef.h>

static sem_t polymake_wasm_fake_sem;

int sem_unlink(const char* name)
{
   (void)name;
   return 0;
}

sem_t* sem_open(const char* name, int oflag, ...)
{
   (void)name; (void)oflag;
   return &polymake_wasm_fake_sem;
}

int sem_getvalue(sem_t* sem, int* sval)
{
   (void)sem;
   if (sval) *sval = 1;
   return 0;
}

int sem_close(sem_t* sem)
{
   (void)sem;
   return 0;
}

struct polymake_wasm_cpu_set;

int pthread_getaffinity_np(unsigned long thread, size_t cpusetsize, struct polymake_wasm_cpu_set* cpuset)
{
   (void)thread; (void)cpusetsize; (void)cpuset;
   return 0;
}

int pthread_setaffinity_np(unsigned long thread, size_t cpusetsize, const struct polymake_wasm_cpu_set* cpuset)
{
   (void)thread; (void)cpusetsize; (void)cpuset;
   return 0;
}

/* Singular's resource setup.
 *
 * libsingular locates its library tree, and the rest of its resources, from the
 * path of the running executable, falling back to a set of environment
 * variables.  Neither works here: there is no executable path to discover in a
 * static wasm binary, and the paths compiled into libsingular_resources point at
 * the prefix the singular package was built in, which does not exist inside the
 * wasm filesystem image.  Without them siInit() aborts with
 * "Could not get expanded executable ..." / "Could not get 'DefaultDir'".
 *
 * Emscripten does not import the host environment, so these cannot be set from
 * outside the program; they have to be set here, before anything calls siInit().
 * A constructor covers polymake's own driver as well as any other program that
 * links libpolymake.a.  overwrite=0 keeps an embedder's own settings.
 *
 * POLYMAKE_WASM_SINGULAR_DIR is where build.sh mounts the singular package's
 * share/singular directory in the image, so that its LIB subdirectory is what
 * SINGULARPATH points at.
 */

#ifndef POLYMAKE_WASM_SINGULAR_DIR
#define POLYMAKE_WASM_SINGULAR_DIR "/polymake/singular"
#endif

#include <stdlib.h>

__attribute__((constructor))
static void polymake_wasm_singular_env(void)
{
   setenv("SINGULAR_ROOT_DIR",    POLYMAKE_WASM_SINGULAR_DIR, 0);
   setenv("SINGULAR_DEFAULT_DIR", POLYMAKE_WASM_SINGULAR_DIR, 0);
   setenv("SINGULAR_BIN_DIR",     POLYMAKE_WASM_SINGULAR_DIR, 0);
   setenv("SINGULAR_EXECUTABLE",  POLYMAKE_WASM_SINGULAR_DIR "/Singular", 0);
   setenv("SINGULARPATH",         POLYMAKE_WASM_SINGULAR_DIR "/LIB", 0);
}
