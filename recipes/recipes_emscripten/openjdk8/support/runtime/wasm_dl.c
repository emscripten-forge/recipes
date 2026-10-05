/*
 * wasm_dl.c -- dlopen()/dlsym()/dladdr() for the statically linked
 * WebAssembly OpenJDK.
 *
 * Every native library of the JDK is linked into the one WebAssembly module.
 * dlopen("…/libNAME.so") succeeds for the libraries that were linked in and
 * returns a handle for them; dlsym() then finds functions in the generated
 * symbol table.  JNI_OnLoad/JNI_OnUnload are resolved per library (they are
 * compiled as JNI_OnLoad_NAME, the JEP 178 name of a built-in library).
 *
 * Copyright (c) 2026 emscripten-forge contributors.  GPL-2.0 with Classpath
 * exception, like the rest of OpenJDK.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <link.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wasm_dlsym.h"

#define HANDLE_MAGIC 0x4a444c48 /* "JDLH" */
#define MAX_LIBS 128

struct wasm_dl_handle {
  int magic;
  int lib;                 /* -1: whole program */
  int refs;
};

static struct wasm_dl_handle process_handle = { HANDLE_MAGIC, -1, 1 };
static struct wasm_dl_handle lib_handles[MAX_LIBS];
static char dl_error_buf[512];
static int dl_error_pending;

static void set_error(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(dl_error_buf, sizeof dl_error_buf, fmt, ap);
  va_end(ap);
  dl_error_pending = 1;
}

static const char *java_home(void) {
  const char *h = getenv("JAVA_HOME");
  return (h && *h) ? h : "/java";
}

static void *lookup(const char *name) {
  int lo = 0, hi = wasm_dl_symbol_count - 1;
  while (lo <= hi) {
    int mid = (lo + hi) / 2;
    int c = strcmp(wasm_dl_symbols[mid].name, name);
    if (c == 0) return wasm_dl_symbols[mid].addr;
    if (c < 0) lo = mid + 1; else hi = mid - 1;
  }
  return NULL;
}

/* "…/libfoo.so.1" -> "foo" */
static void library_name(const char *path, char *out, size_t len) {
  const char *base = strrchr(path, '/');
  base = base ? base + 1 : path;
  if (strncmp(base, "lib", 3) == 0) base += 3;
  size_t n = strcspn(base, ".");
  if (n >= len) n = len - 1;
  memcpy(out, base, n);
  out[n] = 0;
}

void *dlopen(const char *file, int mode) {
  (void)mode;
  if (file == NULL) return &process_handle;
  char name[128];
  library_name(file, name, sizeof name);
  for (int i = 0; wasm_dl_libraries[i] && i < MAX_LIBS; i++) {
    if (strcmp(name, wasm_dl_libraries[i]) == 0) {
      struct wasm_dl_handle *h = &lib_handles[i];
      h->magic = HANDLE_MAGIC;
      h->lib = i;
      h->refs++;
      return h;
    }
  }
  set_error("%s: cannot open shared object file: library is not part of this "
            "WebAssembly build", file);
  return NULL;
}

int dlclose(void *handle) {
  struct wasm_dl_handle *h = handle;
  if (!h || h->magic != HANDLE_MAGIC) {
    set_error("dlclose: invalid handle");
    return -1;
  }
  if (h->refs > 0) h->refs--;
  return 0;
}

void *dlsym(void *restrict handle, const char *restrict name) {
  struct wasm_dl_handle *h = handle;
  int lib = -1;
  if (handle != RTLD_DEFAULT && handle != RTLD_NEXT && h && h->magic == HANDLE_MAGIC)
    lib = h->lib;
  if (lib >= 0 && (strcmp(name, "JNI_OnLoad") == 0 || strcmp(name, "JNI_OnUnload") == 0)) {
    char buf[160];
    snprintf(buf, sizeof buf, "%s_%s", name, wasm_dl_libraries[lib]);
    void *p = lookup(buf);
    if (!p) set_error("undefined symbol: %s", name);
    return p;
  }
  void *p = lookup(name);
  if (!p) set_error("undefined symbol: %s", name);
  return p;
}

char *dlerror(void) {
  if (!dl_error_pending) return NULL;
  dl_error_pending = 0;
  return dl_error_buf;
}

/* Paths reported for code addresses: the libraries keep their usual place
 * in the JRE image (the files there are placeholders). */
static char dladdr_path[512];

int dladdr(const void *addr, Dl_info *info) {
  const char *lib = "jvm";
  const char *sname = NULL;
  for (int i = 0; i < wasm_dl_symbol_count; i++) {
    if (wasm_dl_symbols[i].addr == addr) {
      lib = wasm_dl_libraries[wasm_dl_symbols[i].lib];
      sname = wasm_dl_symbols[i].name;
      break;
    }
  }
  if (strcmp(lib, "jvm") == 0)
    snprintf(dladdr_path, sizeof dladdr_path, "%s/lib/wasm32/server/libjvm.so", java_home());
  else if (strcmp(lib, "jli") == 0)
    snprintf(dladdr_path, sizeof dladdr_path, "%s/lib/wasm32/jli/libjli.so", java_home());
  else
    snprintf(dladdr_path, sizeof dladdr_path, "%s/lib/wasm32/lib%s.so", java_home(), lib);
  info->dli_fname = dladdr_path;
  info->dli_fbase = (void *)1;
  info->dli_sname = sname;
  info->dli_saddr = sname ? (void *)addr : NULL;
  return 1;
}

/* Called by musl's pthread_exit(); defining it here keeps libc's own
 * dlerror() implementation out of the link. */
void __dl_thread_cleanup(void) {}

int dl_iterate_phdr(int (*callback)(struct dl_phdr_info *, size_t, void *), void *data) {
  (void)callback; (void)data;
  return 0;
}
