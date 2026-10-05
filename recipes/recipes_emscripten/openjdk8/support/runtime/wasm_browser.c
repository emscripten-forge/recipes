/*
 * wasm_browser.c -- JNI natives of org.emscriptenforge.jvm.* : HTTP(S)
 * through the browser's fetch(), applet page services and a small
 * LiveConnect bridge (netscape.javascript.JSObject).
 *
 * Built into the WebAssembly OpenJDK as the built-in library "wasmrt".
 */
#include <jni.h>
#include <stdlib.h>
#include <string.h>
#include <gthread.h>

#include "wasm_runtime.h"

/* wasmrt_lib.js */
extern int wasm_fetch_start(const char *url, const char *method, const char *headers,
                            const void *body, int body_len);
extern int wasm_fetch_done(int id);
extern int wasm_fetch_status(int id);
extern char *wasm_fetch_string(int id, int which);
extern int wasm_fetch_body_length(int id);
extern void wasm_fetch_body_copy(int id, void *dst);
extern void wasm_fetch_free(int id);
extern void wasm_browser_show_document(const char *url, const char *target);
extern void wasm_browser_show_status(const char *text);
extern char *wasm_browser_page_url(void);
extern char *wasm_js_op(int op, int handle, const char *name, const char *args);

JNIEXPORT jint JNICALL JNI_OnLoad_wasmrt(JavaVM *vm, void *reserved) {
  (void)vm; (void)reserved;
  return JNI_VERSION_1_8;
}

static char *dup_utf(JNIEnv *env, jstring s) {
  if (s == NULL) return NULL;
  const char *u = (*env)->GetStringUTFChars(env, s, NULL);
  if (u == NULL) return NULL;
  char *r = strdup(u);
  (*env)->ReleaseStringUTFChars(env, s, u);
  return r;
}

static jstring take_string(JNIEnv *env, char *s) {
  if (s == NULL) return NULL;
  jstring r = (*env)->NewStringUTF(env, s);
  free(s);
  return r;
}

/* ------------------------------------------------ FetchURLConnection */

JNIEXPORT jint JNICALL
Java_org_emscriptenforge_jvm_net_FetchURLConnection_start0(JNIEnv *env, jclass cls,
    jstring url, jstring method, jstring headers, jbyteArray body) {
  (void)cls;
  char *u = dup_utf(env, url), *m = dup_utf(env, method), *h = dup_utf(env, headers);
  jbyte *b = NULL;
  jint blen = -1;
  if (body != NULL) {
    blen = (*env)->GetArrayLength(env, body);
    b = (*env)->GetByteArrayElements(env, body, NULL);
  }
  int id = wasm_fetch_start(u ? u : "", m ? m : "GET", h, b, blen);
  if (b) (*env)->ReleaseByteArrayElements(env, body, b, JNI_ABORT);
  free(u); free(m); free(h);
  return id;
}

/* Blocks the calling (green) thread until the request has completed. */
JNIEXPORT void JNICALL
Java_org_emscriptenforge_jvm_net_FetchURLConnection_await0(JNIEnv *env, jclass cls, jint id) {
  (void)env; (void)cls;
  while (!wasm_fetch_done(id)) gt_io_wait(WASM_CHANNEL_FETCH, -1);
}

JNIEXPORT jint JNICALL
Java_org_emscriptenforge_jvm_net_FetchURLConnection_status0(JNIEnv *env, jclass cls, jint id) {
  (void)env; (void)cls;
  return wasm_fetch_status(id);
}

JNIEXPORT jstring JNICALL
Java_org_emscriptenforge_jvm_net_FetchURLConnection_string0(JNIEnv *env, jclass cls,
    jint id, jint which) {
  (void)cls;
  return take_string(env, wasm_fetch_string(id, which));
}

JNIEXPORT jbyteArray JNICALL
Java_org_emscriptenforge_jvm_net_FetchURLConnection_body0(JNIEnv *env, jclass cls, jint id) {
  (void)cls;
  int n = wasm_fetch_body_length(id);
  if (n < 0) return NULL;
  jbyteArray a = (*env)->NewByteArray(env, n);
  if (a == NULL || n == 0) return a;
  jbyte *p = (*env)->GetByteArrayElements(env, a, NULL);
  if (p == NULL) return NULL;
  wasm_fetch_body_copy(id, p);
  (*env)->ReleaseByteArrayElements(env, a, p, 0);
  return a;
}

JNIEXPORT void JNICALL
Java_org_emscriptenforge_jvm_net_FetchURLConnection_free0(JNIEnv *env, jclass cls, jint id) {
  (void)env; (void)cls;
  wasm_fetch_free(id);
}

/* ----------------------------------------------------------- Browser */

JNIEXPORT void JNICALL
Java_org_emscriptenforge_jvm_Browser_showDocument0(JNIEnv *env, jclass cls, jstring url,
    jstring target) {
  (void)cls;
  char *u = dup_utf(env, url), *t = dup_utf(env, target);
  if (u) wasm_browser_show_document(u, t);
  free(u); free(t);
}

JNIEXPORT void JNICALL
Java_org_emscriptenforge_jvm_Browser_showStatus0(JNIEnv *env, jclass cls, jstring text) {
  (void)cls;
  char *s = dup_utf(env, text);
  wasm_browser_show_status(s ? s : "");
  free(s);
}

JNIEXPORT jstring JNICALL
Java_org_emscriptenforge_jvm_Browser_pageURL0(JNIEnv *env, jclass cls) {
  (void)cls;
  return take_string(env, wasm_browser_page_url());
}

/* LiveConnect: op, handle, name and tagged arguments separated by U+001F
 * (see org.emscriptenforge.jvm.Browser). */
JNIEXPORT jstring JNICALL
Java_org_emscriptenforge_jvm_Browser_jsOp0(JNIEnv *env, jclass cls, jint op, jint handle,
    jstring name, jstring args) {
  (void)cls;
  char *n = dup_utf(env, name);
  char *a = dup_utf(env, args);
  char *r = wasm_js_op(op, handle, n, a);
  free(n); free(a);
  return take_string(env, r);
}
