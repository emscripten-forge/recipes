/* execinfo.h -- compatibility header for building OpenJDK with Emscripten:
 * native backtraces are not available (use the browser's devtools). */
#ifndef _COMPAT_EXECINFO_H
#define _COMPAT_EXECINFO_H
#include <stddef.h>
static inline int backtrace(void **buffer, int size) { (void)buffer; (void)size; return 0; }
static inline char **backtrace_symbols(void *const *buffer, int size) {
  (void)buffer; (void)size; return NULL;
}
static inline void backtrace_symbols_fd(void *const *buffer, int size, int fd) {
  (void)buffer; (void)size; (void)fd;
}
#endif
