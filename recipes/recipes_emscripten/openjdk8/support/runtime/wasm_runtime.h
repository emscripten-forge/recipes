/*
 * wasm_runtime.h -- shared definitions of the WebAssembly OpenJDK runtime.
 */
#ifndef WASM_RUNTIME_H
#define WASM_RUNTIME_H

/* gthread I/O channels */
#define WASM_CHANNEL_X11    1   /* X events and AWT wake-ups */
#define WASM_CHANNEL_FETCH  2   /* completed fetch() requests */
#define WASM_CHANNEL_STDIN  3   /* console input */
/* channel 4 is reserved */

#define WASM_X11_CONNECTION_FD (0x7ff00000 + 1)

#endif
