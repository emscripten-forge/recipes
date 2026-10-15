/* Calls C functions through ffi_call with 64-bit arguments and results at
   addresses that are 4- but not 8-byte aligned, which a 32-bit C ABI allows
   and OpenJDK Zero produces. With -DTEST_PTHREAD the calls are repeated on a
   second thread. Exits with 0 when every result is right. */
#include <ffi.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#ifdef TEST_PTHREAD
#include <pthread.h>
#endif

static double mix(int32_t a, int64_t b, double c) { return a + (double)b * c; }
static int64_t twice(int64_t v) { return 2 * v; }

struct results { double mix; int64_t twice; int rc; };

static void run(struct results *res) {
  _Alignas(8) unsigned char buf[48];
  ffi_cif cif;
  ffi_type *mix_args[3] = { &ffi_type_sint32, &ffi_type_sint64, &ffi_type_double };
  ffi_type *twice_args[1] = { &ffi_type_sint64 };
  int32_t a = 3;
  int64_t b = 5000000000LL;
  double c = 0.5;

  res->rc = 1;
  /* buf + 4, 12, 20, 28: 4-byte aligned, never 8-byte aligned */
  memcpy(buf + 4, &b, 8);
  memcpy(buf + 12, &c, 8);

  void *mix_values[3] = { &a, buf + 4, buf + 12 };
  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 3, &ffi_type_double, mix_args) != FFI_OK) return;
  ffi_call(&cif, FFI_FN(mix), buf + 20, mix_values);
  memcpy(&res->mix, buf + 20, 8);

  void *twice_values[1] = { buf + 4 };
  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_sint64, twice_args) != FFI_OK) return;
  ffi_call(&cif, FFI_FN(twice), buf + 28, twice_values);
  memcpy(&res->twice, buf + 28, 8);

  res->rc = res->mix == 2500000003.0 && res->twice == 10000000000LL ? 0 : 2;
}

static int report(const char *where, const struct results *res) {
  printf("%s: mix=%.1f twice=%lld %s\n", where, res->mix, (long long)res->twice,
         res->rc == 0 ? "ok" : "WRONG");
  return res->rc;
}

#ifdef TEST_PTHREAD
static void *thread_main(void *arg) {
  run(arg);
  return NULL;
}
#endif

int main(void) {
  struct results res = {0};
  run(&res);
  if (report("main thread", &res) != 0) return 1;
#ifdef TEST_PTHREAD
  struct results tres = {0};
  pthread_t t;
  if (pthread_create(&t, NULL, thread_main, &tres) != 0) return 3;
  pthread_join(t, NULL);
  if (report("pthread", &tres) != 0) return 1;
#endif
  return 0;
}
