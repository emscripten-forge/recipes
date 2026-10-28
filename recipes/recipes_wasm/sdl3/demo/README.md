# SDL3 WebAssembly demo

This demo ships with the `sdl3-static` package so the library can be tested
manually in a browser. It follows the
[SDL Emscripten guide](https://github.com/libsdl-org/SDL/blob/main/docs/README-emscripten.md):

- It uses SDL3 main callbacks (`SDL_MAIN_USE_CALLBACKS`) instead of a blocking
  `main()` loop.
- Rendering happens in `SDL_AppIterate()`, which returns after each frame.
- Vsync is enabled so the browser's `requestAnimationFrame` drives the loop.
- The build links with `-sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=1gb`.

The installed package contains:

```text
share/sdl3-demo/sdl3-demo.html
share/sdl3-demo/sdl3-demo.js
share/sdl3-demo/sdl3-demo.wasm
```

Serve the directory with any static HTTP server, for example:

```bash
python -m http.server -d "$CONDA_PREFIX/share/sdl3-demo" 8000
```

Then open <http://localhost:8000/sdl3-demo.html>.

This build uses no threads, so no special COOP/COEP headers are required.

For automated headless testing under Node, pass `--driver dummy --frames 3`
as program arguments (or set `SDL_DEMO_FRAMES`) to make the demo quit after a
fixed number of frames. The environment variable can also be passed in the
page URL, because SDL3 copies URL parameters beginning with `SDL_` into
environment variables:

```text
http://localhost:8000/sdl3-demo.html?SDL_DEMO_FRAMES=3
```
