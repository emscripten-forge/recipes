// wasm64 version of Python/emscripten_trampoline_inner.c (CPython's wasm-gc
// call trampoline), compiled with clang -target wasm64-unknown-unknown -mgc
// (build.sh) and loaded at runtime by Python/emscripten_trampoline.c.
//
// Differences to the wasm32 version:
//
// * The signature test is done with inline assembly (table.get + ref.test):
//   clang lowers __builtin_wasm_test_function_pointer_signature to a table.get
//   with an i32 index (i32.wrap_i64), which is invalid for the table64 of a
//   wasm64 (memory64) main module.
//
// * On wasm32 a C `int` and a pointer are both i32. On wasm64 functions
//   returning `int` have a different wasm type, and CPython also calls those
//   through the trampoline (e.g. descriptor setters, descr_set_trampoline_call,
//   which casts the result back to int): they are handled too.
//
// Like the wasm32 version this is compiled with -nostdlib and does not include
// Python.h.

typedef void PyObject;

typedef PyObject* (*three_arg)(PyObject*, PyObject*, PyObject*);
typedef PyObject* (*two_arg)(PyObject*, PyObject*);
typedef PyObject* (*one_arg)(PyObject*);
typedef PyObject* (*zero_arg)(void);

typedef int (*three_arg_int)(PyObject*, PyObject*, PyObject*);
typedef int (*two_arg_int)(PyObject*, PyObject*);
typedef int (*one_arg_int)(PyObject*);
typedef int (*zero_arg_int)(void);

// ref.test of the table entry `func` against the wasm function type `sig`
#define DEFINE_SIGNATURE_TEST(name, sig)                                      \
  static inline int name(void* func)                                          \
  {                                                                           \
    int result;                                                               \
    __asm__("local.get %1\n"                                                  \
            "table.get __indirect_function_table\n"                           \
            "ref.test " sig "\n"                                              \
            "local.set %0\n"                                                  \
            : "=r"(result)                                                    \
            : "r"(func));                                                     \
    return result;                                                            \
  }

DEFINE_SIGNATURE_TEST(is_three_arg, "(i64, i64, i64) -> (i64)")
DEFINE_SIGNATURE_TEST(is_two_arg, "(i64, i64) -> (i64)")
DEFINE_SIGNATURE_TEST(is_one_arg, "(i64) -> (i64)")
DEFINE_SIGNATURE_TEST(is_zero_arg, "() -> (i64)")
DEFINE_SIGNATURE_TEST(is_three_arg_int, "(i64, i64, i64) -> (i32)")
DEFINE_SIGNATURE_TEST(is_two_arg_int, "(i64, i64) -> (i32)")
DEFINE_SIGNATURE_TEST(is_one_arg_int, "(i64) -> (i32)")
DEFINE_SIGNATURE_TEST(is_zero_arg_int, "() -> (i32)")

__attribute__((export_name("trampoline_call"))) PyObject*
trampoline_call(int* success,
                void* func,
                PyObject* self,
                PyObject* args,
                PyObject* kw)
{
  *success = 1;
  if (is_three_arg(func)) {
    return ((three_arg)func)(self, args, kw);
  }
  if (is_two_arg(func)) {
    return ((two_arg)func)(self, args);
  }
  if (is_one_arg(func)) {
    return ((one_arg)func)(self);
  }
  if (is_zero_arg(func)) {
    return ((zero_arg)func)();
  }
  // int results, sign-extended (the caller casts back to int)
  if (is_three_arg_int(func)) {
    return (PyObject*)(long)((three_arg_int)func)(self, args, kw);
  }
  if (is_two_arg_int(func)) {
    return (PyObject*)(long)((two_arg_int)func)(self, args);
  }
  if (is_one_arg_int(func)) {
    return (PyObject*)(long)((one_arg_int)func)(self);
  }
  if (is_zero_arg_int(func)) {
    return (PyObject*)(long)((zero_arg_int)func)();
  }
  *success = 0;
  return 0;
}
