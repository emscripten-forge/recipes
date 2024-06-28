# Troubleshooting


Compiling for emscripten-wasm32 is a complex task. This section provides some tips and tricks to help you troubleshoot common issues.

## Buildtime errors

This section is still empty, feel free to contribute by opening a pull request.

## Runtime errors

### `PyLong_FromLongLong`: imported function does not match the expected type

When facing an error at runtime while importing a shared-library / python-package like the following:
```
 LinkError: WebAssembly.instantiate():
    function="PyLong_FromLongLong":
    imported function does not match the expected type
```
or an error message containing `*LongLong` or similar wording, it is likely that
the linker flag `-s WASM_BIGINT` is missing.
