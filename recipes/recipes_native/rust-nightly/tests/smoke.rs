use std::ffi::c_void;

#[unsafe(no_mangle)]
pub extern "C" fn smoke_add(a: i64, b: i64) -> i64 {
    let v: Vec<i64> = (0..8).map(|i| i * a).collect();
    std::hint::black_box(v.as_ptr() as *const c_void);
    a + b + v[1]
}
