# Emscripten-Forge Documentation

Follow the instructions below to build the documentation locally.

1. Install `pixi` in your environment.

    ```bash
    micromamba install pixi -c conda-forge
    ```

2. Build the documentation.

    ```bash
    pixi run docs-build -d _build

    ```

3. The generated documentation can be found in the `_build` directory. Use your favorite server.

    ```bash
    cd _build
    python -m http.server
    ```
