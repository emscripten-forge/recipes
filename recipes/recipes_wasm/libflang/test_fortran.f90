program fortran_test
  use, intrinsic :: iso_c_binding
  implicit none

  integer(c_long) :: long_val
  integer(c_size_t) :: size_val
  integer(c_intptr_t) :: intptr_val
  integer(c_ptrdiff_t) :: ptrdiff_val
  type(c_ptr) :: ptr
  type(c_funptr) :: funptr
  integer(c_size_t) :: expected, expected_cptr, actual

#if defined(__wasm32__)
  expected = 4_c_size_t
  if (c_long /= c_int32_t) error stop "c_long kind != 4 on wasm32"
#elif defined(__wasm64__)
  expected = 8_c_size_t
  if (c_long /= c_int64_t) error stop "c_long kind != 8 on wasm64"
#else
  error stop "expected __wasm32__ or __wasm64__"
#endif
  ! Flang models c_ptr/c_funptr as __builtin_c_ptr{__address:i64} on all targets.
  expected_cptr = 8_c_size_t

  actual = c_sizeof(long_val)
  if (actual /= expected) then
    print *, "c_long size:", actual, "expected:", expected
    error stop "unexpected c_long size"
  end if
  print *, "c_long size:", actual

  actual = c_sizeof(size_val)
  if (actual /= expected) then
    print *, "c_size_t size:", actual, "expected:", expected
    error stop "unexpected c_size_t size"
  end if
  print *, "c_size_t size:", actual

  actual = c_sizeof(intptr_val)
  if (actual /= expected) then
    print *, "c_intptr_t size:", actual, "expected:", expected
    error stop "unexpected c_intptr_t size"
  end if
  print *, "c_intptr_t size:", actual

  actual = c_sizeof(ptrdiff_val)
  if (actual /= expected) then
    print *, "c_ptrdiff_t size:", actual, "expected:", expected
    error stop "unexpected c_ptrdiff_t size"
  end if
  print *, "c_ptrdiff_t size:", actual

  actual = c_sizeof(ptr)
  if (actual /= expected_cptr) then
    print *, "c_ptr size:", actual, "expected:", expected_cptr
    error stop "unexpected c_ptr size"
  end if
  print *, "c_ptr size:", actual

  actual = c_sizeof(funptr)
  if (actual /= expected_cptr) then
    print *, "c_funptr size:", actual, "expected:", expected_cptr
    error stop "unexpected c_funptr size"
  end if
  print *, "c_funptr size:", actual

  print *, "Great success!"
end program fortran_test
