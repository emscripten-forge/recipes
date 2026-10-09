/* A "native method" called through ffi_call suspends with JSPI (as a JNI
   method does when it blocks and gthread-jspi switches green threads), then
   resumes and returns a 64-bit result. */
#include <ffi.h>
#include <emscripten.h>
#include <stdint.h>
#include <stdio.h>

EM_ASYNC_JS(int, wait_and_add_one, (int a), {
  await new Promise(resolve => setTimeout(resolve, 10));
  return a + 1;
});

static int64_t native_method(int32_t x, int64_t y) {
  return wait_and_add_one(x) + y;
}

int main(void) {
  ffi_cif cif;
  ffi_type *args[2] = { &ffi_type_sint32, &ffi_type_sint64 };
  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_sint64, args) != FFI_OK) return 2;
  int32_t x = 41;
  int64_t y = 5000000000LL, r = 0;
  void *values[2] = { &x, &y };
  ffi_call(&cif, FFI_FN(native_method), &r, values);
  printf("suspended inside ffi_call, resumed: %lld %s\n", (long long)r,
         r == 5000000042LL ? "ok" : "WRONG");
  return r == 5000000042LL ? 0 : 1;
}
