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