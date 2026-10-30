// Links Rust code that calls poll() through std's libc together with C code
// that calls poll() (tests/poll_user.c). If std's libc declares nfds_t
// differently from emscripten's <poll.h>, wasm-ld fails with
// "function signature mismatch: poll" (seen with libc 0.2.189 on wasm64).
#![feature(rustc_private)]
extern crate libc;

extern "C" {
    fn c_poll_user() -> i32;
}

#[no_mangle]
pub extern "C" fn rust_poll_user() -> i32 {
    let mut fd = libc::pollfd { fd: 0, events: libc::POLLIN, revents: 0 };
    let r = unsafe { libc::poll(&mut fd, 1, 0) };
    r + unsafe { c_poll_user() }
}
