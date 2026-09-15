program fortran_test
  use, intrinsic :: iso_c_binding
  implicit none

  integer(c_long) :: long_val
  integer(c_size_t) :: size_val
  integer(c_intptr_t) :: intptr_val
  integer(c_ptrdiff_t) :: ptrdiff_val
  type(c_ptr) :: ptr
  type(c_funptr) :: funptr
  integer(c_size_t) :: expected

#if defined(__wasm32__)
  expected = 4_c_size_t
  if (c_long /= c_int32_t) error stop "c_long kind != 4 on wasm32"
#elif defined(__wasm64__)
  expected = 8_c_size_t
  if (c_long /= c_int64_t) error stop "c_long kind != 8 on wasm64"
#else
  error stop "expected __wasm32__ or __wasm64__"
#endif

  if (c_sizeof(long_val) /= expected) error stop "unexpected c_long size"
  print *, "c_long size:", c_sizeof(long_val)

  if (c_sizeof(size_val) /= expected) error stop "unexpected c_size_t size"
  print *, "c_size_t size:", c_sizeof(size_val)

  if (c_sizeof(intptr_val) /= expected) error stop "unexpected c_intptr_t size"
  print *, "c_intptr_t size:", c_sizeof(intptr_val)

  if (c_sizeof(ptrdiff_val) /= expected) error stop "unexpected c_ptrdiff_t size"
  print *, "c_ptrdiff_t size:", c_sizeof(ptrdiff_val)

  if (c_sizeof(ptr) /= expected) error stop "unexpected c_ptr size"
  print *, "c_ptr size:", c_sizeof(ptr)

  if (c_sizeof(funptr) /= expected) error stop "unexpected c_funptr size"
  print *, "c_funptr size:", c_sizeof(funptr)

  print *, "Great success!"
end program fortran_test
