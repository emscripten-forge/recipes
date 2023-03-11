import importlib.resources

resource = importlib.resources.files("pyodide_build")
with importlib.resources.as_file(
    resource / "tools" / "cmake" / "Modules" / "Platform" / "Emscripten.cmake"
) as path:
    ...

assert path.exists()
print(path)
