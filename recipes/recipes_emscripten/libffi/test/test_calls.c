/*
 * libffi on Emscripten: scalar calls (WebAssembly trampolines when the table
 * can grow, JavaScript otherwise), structures by value, varargs and
 * closures (JavaScript implementation; -DNO_CLOSURES without
 * -sALLOW_TABLE_GROWTH).
 */
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <ffi.h>

static int fails;
#define CHECK(cond, ...) do { if (!(cond)) { printf("FAIL: " __VA_ARGS__); puts(""); fails++; } } while (0)

static uint8_t ret_u8(void) { return 0xff; }
static int8_t ret_s8(void) { return -2; }
static uint16_t ret_u16(uint16_t x) { return x + 1; }
static int64_t mul64(int64_t a, int32_t b) { return a * b; }
static float halve(float x) { return x / 2; }
static double mix(int8_t a, int64_t b, float c, double d, uint16_t e, void *p) {
  return a + (double) b + c + d + e + (p ? 1 : 0);
}
static int calls;
static void bump(void) { calls++; }

struct point { int x, y; double w; };
static double norm1(struct point p) { return p.x + p.y + p.w; }
static struct point make_point(int x, int y) { struct point p = { x, y, 0.5 }; return p; }

static int sum_ints(int n, ...) {
  va_list ap;
  int s = 0;
  va_start(ap, n);
  for (int i = 0; i < n; i++) s += va_arg(ap, int);
  va_end(ap);
  return s;
}

static void closure_fn(ffi_cif *cif, void *ret, void **args, void *user) {
  *(ffi_arg *) ret = *(int *) args[0] * *(int *) user;
}

int main(void) {
  ffi_cif cif;
  ffi_arg r = 0;

  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 0, &ffi_type_uint8, NULL);
  memset(&r, 0x55, sizeof r);
  ffi_call(&cif, FFI_FN(ret_u8), &r, NULL);
  CHECK((uint8_t) r == 0xff, "uint8 return %lx", (unsigned long) r);

  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 0, &ffi_type_sint8, NULL);
  ffi_call(&cif, FFI_FN(ret_s8), &r, NULL);
  CHECK((int8_t) r == -2, "sint8 return %lx", (unsigned long) r);

  ffi_type *t16[1] = { &ffi_type_uint16 };
  uint16_t v16 = 41;
  void *a16[1] = { &v16 };
  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_uint16, t16);
  ffi_call(&cif, FFI_FN(ret_u16), &r, a16);
  CHECK((uint16_t) r == 42, "uint16 call %lx", (unsigned long) r);

  ffi_type *tm[2] = { &ffi_type_sint64, &ffi_type_sint32 };
  int64_t big = 3000000000LL;
  int32_t three = 3;
  void *am[2] = { &big, &three };
  int64_t r64 = 0;
  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_sint64, tm);
  ffi_call(&cif, FFI_FN(mul64), &r64, am);
  CHECK(r64 == 9000000000LL, "int64 call %lld", (long long) r64);

  ffi_type *tf[1] = { &ffi_type_float };
  float f = 5.0f, rf = 0;
  void *af[1] = { &f };
  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_float, tf);
  ffi_call(&cif, FFI_FN(halve), &rf, af);
  CHECK(rf == 2.5f, "float call %f", rf);

  ffi_type *tx[6] = { &ffi_type_sint8, &ffi_type_sint64, &ffi_type_float,
                      &ffi_type_double, &ffi_type_uint16, &ffi_type_pointer };
  int8_t xa = -3; int64_t xb = 5000000000LL; float xc = 0.5f; double xd = 0.25;
  uint16_t xe = 65535; void *xp = &calls;
  void *ax[6] = { &xa, &xb, &xc, &xd, &xe, &xp };
  double rd = 0;
  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 6, &ffi_type_double, tx);
  ffi_call(&cif, FFI_FN(mix), &rd, ax);
  CHECK(rd == 5000065533.75, "mixed call %f", rd);

  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 0, &ffi_type_void, NULL);
  ffi_call(&cif, FFI_FN(bump), NULL, NULL);
  CHECK(calls == 1, "void call");

  /* 64-bit arguments that are only 4-byte aligned (a 32-bit ABI allows it;
   * OpenJDK's Zero passes pointers to such interpreter stack slots) */
  {
    uint32_t slots[8];
    char *base = (char *) slots;
    if (((uintptr_t) base & 7) == 0) base += 4;   /* 4 mod 8 */
    int64_t ub = 5000000000LL;
    double ud = 0.25;
    memcpy(base, &ub, 8);
    memcpy(base + 8, &ud, 8);
    int8_t ua = -3; float uc = 0.5f; uint16_t ue = 65535; void *up = NULL;
    void *au[6] = { &ua, base, &uc, base + 8, &ue, &up };
    rd = 0;
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 6, &ffi_type_double, tx);
    ffi_call(&cif, FFI_FN(mix), &rd, au);
    CHECK(rd == 5000065532.75, "unaligned 64-bit arguments %f", rd);
  }

  /* structures by value */
  ffi_type *pt_elems[4] = { &ffi_type_sint32, &ffi_type_sint32, &ffi_type_double, NULL };
  ffi_type pt = { 0, 0, FFI_TYPE_STRUCT, pt_elems };
  ffi_type *ts[1] = { &pt };
  struct point p = { 1, 2, 0.25 };
  void *as[1] = { &p };
  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_double, ts);
  ffi_call(&cif, FFI_FN(norm1), &rd, as);
  CHECK(rd == 3.25, "struct argument %f", rd);
  ffi_type *ti2[2] = { &ffi_type_sint32, &ffi_type_sint32 };
  int px = 7, py = 8;
  void *ap2[2] = { &px, &py };
  struct point rp = { 0, 0, 0 };
  ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &pt, ti2);
  ffi_call(&cif, FFI_FN(make_point), &rp, ap2);
  CHECK(rp.x == 7 && rp.y == 8 && rp.w == 0.5, "struct return");

  /* varargs */
  ffi_type *tv[4] = { &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32 };
  int n = 3, v1 = 10, v2 = 20, v3 = 30;
  void *av[4] = { &n, &v1, &v2, &v3 };
  ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, 1, 4, &ffi_type_sint32, tv);
  ffi_call(&cif, FFI_FN(sum_ints), &r, av);
  CHECK((int) r == 60, "varargs %d", (int) r);

#ifndef NO_CLOSURES
  /* closures (need -sALLOW_TABLE_GROWTH) */
  void *code;
  ffi_closure *cl = ffi_closure_alloc(sizeof(ffi_closure), &code);
  int factor = 6;
  ffi_type *tc[1] = { &ffi_type_sint32 };
  ffi_cif ccif;
  ffi_prep_cif(&ccif, FFI_DEFAULT_ABI, 1, &ffi_type_sint32, tc);
  if (cl && ffi_prep_closure_loc(cl, &ccif, closure_fn, &factor, code) == FFI_OK) {
    int (*times)(int) = (int (*)(int)) code;
    CHECK(times(7) == 42, "closure %d", times(7));
    ffi_closure_free(cl);
  } else {
    CHECK(0, "closure allocation");
  }
#endif

  puts(fails ? "LIBFFI CALL TEST FAILED" : "LIBFFI CALL TEST OK");
  return fails != 0;
}
