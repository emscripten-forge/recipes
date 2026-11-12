#include <Python.h>

extern "C" int run_python(const char * code)
{
    Py_Initialize();

    // PyRun_SimpleString returns 0 on success, -1 on exception
    int res = PyRun_SimpleString(code);
    int status = 0;

    if (res != 0) {
        // PyErr_Print prints the formatted exception and traceback to stderr
        PyErr_Print();
        status = 1; // Indicate Python execution error
    }

    if (Py_FinalizeEx() < 0) {
        status = 2; // Indicate finalization error
    }

    return status;
}

// --- call trampoline (Python/emscripten_trampoline.c) ----------------------
// _PyRuntime.emscripten_trampoline != 0 <=> the wasm-gc trampoline is used
// (no JS frames when python calls C functions, needed for JSPI stack switching)
#include <cstring>
extern "C" {
    extern const int _PyEM_EMSCRIPTEN_TRAMPOLINE_OFFSET;
    extern char _PyRuntime[];
}

extern "C" int uses_wasm_gc_trampoline()
{
    void* trampoline = nullptr;
    std::memcpy(&trampoline, _PyRuntime + _PyEM_EMSCRIPTEN_TRAMPOLINE_OFFSET, sizeof(trampoline));
    return trampoline != nullptr ? 1 : 0;
}

extern "C" int pointer_size()
{
    return static_cast<int>(sizeof(void*));
}
