/*
 * libffi on Emscripten with JSPI: a function called through ffi_call
 * suspends WebAssembly (EM_ASYNC_JS) before it returns.  This works only
 * when ffi_call uses a WebAssembly trampoline (no JavaScript frame between
 * the promising export and the suspending import).
 *   emcc -sJSPI -sJSPI_EXPORTS=main test_jspi.c trampolines.c -lffi
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <emscripten.h>
#include <ffi.h>

EM_ASYNC_JS(int, async_delay, (int ms), {
  await new Promise((resolve) => setTimeout(resolve, ms));
  return ms;
});

static double target(int8_t a, int64_t b, float c, double d, uint16_t e) {
  int waited = async_delay(20);           /* suspends the whole C stack */
  return a + (double) b + c + d + e + waited;
}

static char missing[32];
void ffi_wasm_trampoline_missing(const char *signature) {
  strncpy(missing, signature, sizeof missing - 1);
}

int main(void) {
  ffi_cif cif;
  ffi_type *types[5] = { &ffi_type_sint8, &ffi_type_sint64, &ffi_type_float,
                         &ffi_type_double, &ffi_type_uint16 };
  int8_t a = -3;
  int64_t b = 5000000000LL;
  float c = 0.5f;
  double d = 0.25;
  uint16_t e = 65535;
  void *values[5] = { &a, &b, &c, &d, &e };
  double r = 0;

  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 5, &ffi_type_double, types) != FFI_OK) {
    puts("ffi_prep_cif failed");
    return 1;
  }
  if (missing[0]) printf("no trampoline for %s\n", missing);
  ffi_call(&cif, FFI_FN(target), &r, values);
  if (r != 5000065552.75) {
    printf("wrong result %f\n", r);
    return 1;
  }
  puts("LIBFFI JSPI TEST OK");
  return 0;
}
