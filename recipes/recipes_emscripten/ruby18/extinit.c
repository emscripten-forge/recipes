#include "ruby.h"

/* Statically linked extensions available to require in the wasm build. */
#define init(func, name) {void func _((void)); ruby_init_ext(name, func);}

void ruby_init_ext _((const char *name, void (*init)(void)));

void Init_ext _((void))
{
    init(Init_iconv, "iconv.so");
    init(Init_stringio, "stringio.so");
    init(Init_socket, "socket.so");
    init(Init_etc, "etc.so");
    init(Init_fcntl, "fcntl.so");
    init(Init_thread, "thread.so");
    init(Init_strscan, "strscan.so");
    init(Init_digest, "digest.so");
    init(Init_md5, "digest/md5.so");
}
