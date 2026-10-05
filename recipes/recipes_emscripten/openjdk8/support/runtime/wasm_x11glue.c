/*
 * wasm_x11glue.c -- connects the x11.wasm browser display with the
 * cooperative thread runtime: blocking Xlib calls wait on a gthread I/O
 * channel that is notified whenever the DOM backend queues an event, and
 * ConnectionNumber() returns a virtual file descriptor that poll() treats
 * as readable while X events are queued.
 */
#include <poll.h>
#include <X11/Xlib.h>
#include <X11Wasm/Hooks.h>
#include <gthread.h>

#include "wasm_runtime.h"

static void x11_event_queued(void) {
  gt_io_notify(WASM_CHANNEL_X11);
}

static int x11_wait_event(int timeout_ms) {
  gt_io_wait(WASM_CHANNEL_X11, timeout_ms);
  return 0; /* always re-check the queue */
}

static int x11_poll_hook(int fd, short events, short *revents) {
  (void)fd;
  *revents = 0;
  if ((events & (POLLIN | POLLRDNORM)) && XEventsQueued(NULL, QueuedAfterFlush) > 0)
    *revents = events & (POLLIN | POLLRDNORM);
  return 0;
}

__attribute__((constructor))
static void wasm_x11_glue_init(void) {
  static const X11WasmHooks hooks = {
    x11_event_queued,
    x11_wait_event,
    WASM_X11_CONNECTION_FD,
  };
  X11WasmSetHooks(&hooks);
  gt_register_poll_fd(WASM_X11_CONNECTION_FD, x11_poll_hook, WASM_CHANNEL_X11);
}
