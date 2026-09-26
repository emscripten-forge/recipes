/* main() for the WebAssembly build of Ruby 1.8.7.
 *
 * Ruby raises SystemStackError when the C stack it can see (the shadow stack
 * in linear memory) grows past STACK_LEVEL_MAX.  On wasm the engine's own call
 * stack (about 1 MB in V8, which also holds wasm locals and frames) runs out
 * long before that, and the engine then aborts the whole program with
 * "Maximum call stack size exceeded".  Lower Ruby's limit so runaway
 * recursion is reported as a normal Ruby exception instead.
 *
 * RUBY_WASM_STACK=<bytes> in the environment overrides the default.
 */
#include "ruby.h"
#include <stdlib.h>

void ruby_set_stack_size(size_t);

#ifndef RUBY_WASM_STACK_DEFAULT
#define RUBY_WASM_STACK_DEFAULT (1536 * 1024)
#endif

int
main(int argc, char **argv)
{
    RUBY_INIT_STACK
    ruby_init();
    {
        const char *s = getenv("RUBY_WASM_STACK");
        size_t n = s ? (size_t)strtoul(s, NULL, 10) : 0;
        ruby_set_stack_size(n ? n : RUBY_WASM_STACK_DEFAULT);
    }
    ruby_options(argc, argv);
    ruby_run();
    return 0;
}
