# Experimental Qt runner (`/qtapp/`)

!!! warning "Experimental"

    The purpose of this page is to demonstrate that packaging certain
    Qt applications for the browser via emscripten-forge is
    manageable. Expect rough edges; contributions welcome. Work on
    continued enhancements is ongoing.

A small in-browser runner for Qt6-wasm packages published to the
[emscripten-forge-4x-experimental](https://prefix.dev/channels/emscripten-forge-4x-experimental)
channel. Given the URL of a `.tar.bz2` package (or a locally-picked file),
it fetches, unpacks, and boots the Qt app entirely client-side.

**Try it**: [/qtapp/](/qtapp/)

## Available apps

Currently on the
[emscripten-forge-4x-experimental](https://prefix.dev/channels/emscripten-forge-4x-experimental)
channel:

- **[qt-calculator](/qtapp/?pkg=https%3A%2F%2Frepo.prefix.dev%2Femscripten-forge-4x-experimental%2Femscripten-wasm32%2Fqt-calculator-experimental-6.11.2-hc780342_1.tar.bz2)** —
  Qt's own upstream calculator example
  ([recipe](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/qt-calculator-experimental)).
- **[sqlitebrowser](/qtapp/?pkg=https%3A%2F%2Frepo.prefix.dev%2Femscripten-forge-4x-experimental%2Femscripten-wasm32%2Fsqlitebrowser-experimental-3.13.99-h8b281d3_3.tar.bz2)** —
  DB Browser for SQLite: create tables, run queries, download `.sqlite` files
  ([recipe](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/sqlitebrowser-experimental)).

The exact `.tar.bz2` filename changes on each rebuild (build-hash suffix);
browse the [channel index](https://prefix.dev/channels/emscripten-forge-4x-experimental)
for current URLs.

## Deep-links

Append `?pkg=<URL-encoded package URL>` to auto-load a package on page
open. Both parameters (`?pkg=` and `?fullscreen=1`) can be shared as
regular URLs. Combine as `?pkg=…&fullscreen=1` to start with the top
and status bars hidden — useful for embedding.

## How it works

1. Fetches the `.tar.bz2` (or reads it via file picker / drag-and-drop).
2. Decodes bzip2 and walks the tar entries via
   [`@emscripten-forge/untarjs`](https://www.npmjs.com/package/@emscripten-forge/untarjs).
3. Locates the app under `share/<name>/` inside the package.
4. Wraps every file in that directory as a `blob:` URL, then loads Qt's
   `qtloader.js` and the app's Emscripten glue against those blobs.

## Packaging your own Qt6-wasm app for the runner

In principle, any Qt6-wasm recipe that installs
`share/<name>/{<name>.wasm, <name>.js, qtloader.js}` is loadable. The
runner discovers the app name by scanning for the sole `share/*/*.wasm`
file, so nothing external needs to be configured.

The two reference recipes linked at the end of this section are the
best place to start — copy the one that's closest to your setup and
adapt from there. The bullets below are a quick checklist of the
non-obvious bits to watch for; the recipes show them in context.

- **Depend on the JSPI Qt6 variants** in the recipe's `host:` section —
  `qt6-main-jspi`, plus any of `qt6-5compat-jspi`, `qt6-svg-jspi`,
  `qt6-imageformats-jspi`, `qt6-webchannel-jspi`,
  `qt6-websockets-jspi` your app uses. JSPI is what lets Qt's
  `app.exec()` event loop yield to the browser, so the vanilla
  `qt6-main` won't produce a runnable app.
- **Use Qt's CMake helpers**. `qt_add_executable(<name> …)` is the
  simplest path — it applies the wasm-specific link flags Qt needs
  (embind linkage, `MODULARIZE=1`, `EXPORT_NAME=<name>_entry`, memory
  sizes, JSPI via `INTERFACE`). If you can't call `qt_add_executable`
  (e.g., upstream sources use plain `add_executable` before
  `find_package(Qt6)`), call `qt6_finalize_target(<target>)` at the end
  of the CMakeLists — it applies the same setup.
- **Load Qt's wasm helpers before `find_package(Qt6)`**. On
  emscripten-forge, Sphinx-invoked cmake doesn't source Qt's toolchain
  file automatically; add
  `include("$ENV{PREFIX}/lib/cmake/Qt6/QtPublicWasmToolchainHelpers.cmake")`
  before `find_package(Qt6)` so the target finalization can find
  `_qt_test_emscripten_version` and friends.
- **Synthesize `$EMSDK/.emscripten`** in `build.sh`. Qt's wasm helpers
  read that file; emscripten-forge doesn't ship it. Copy the block
  from the [`qt6/build_qtbase.sh`](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/qt6/build_qtbase.sh)
  recipe verbatim.
- **Install the four artifacts** to `${PREFIX}/share/<name>/`:
  `<name>.wasm`, `<name>.js`, `<name>.html` (optional — runner
  produces its own), `qtloader.js`.
- **Route to the experimental channel** — add
  `extra.channel: emscripten-forge-4x-experimental` to `recipe.yaml`
  until JSPI-Qt reaches the stable channel.
- **Expect wasm-specific patches** for anything non-trivial. Apps that
  haven't been officially wasm-ported need small `#ifdef __EMSCRIPTEN__`
  patches to bridge desktop APIs to what the browser provides and to
  disable features Qt-wasm doesn't ship. The sqlitebrowser recipe
  below, for example, needs seven such patches: routing file open and
  save through `QFileDialog::getOpenFileContent` /
  `saveFileContent`, redirecting "New Database" to an in-memory SQLite,
  stubbing out its SSL-based cloud-sync code path, and a handful of
  smaller build-time fixes (missing header includes,
  `long`-vs-`ptrdiff_t` template instantiations in bundled Scintilla,
  etc.). A good survey of the shapes these fixes take.

### Reference recipes

Both of these are minimal, self-contained, and current:

- **[qt-calculator-experimental](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/qt-calculator-experimental)** —
  hand-written CMakeLists over Qt's own upstream calculator source
  (fetched from the `qtbase` submodule tarball). ~60 LOC total across
  recipe + CMakeLists + build script.
- **[sqlitebrowser-experimental](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/sqlitebrowser-experimental)** —
  a real 50K-LOC third-party Qt widget app patched for wasm. Shows the
  `qt6_finalize_target` route for CMakeLists you don't control, plus
  seven small wasm-specific source patches (SSL stubs, file dialog
  bridging via `QFileDialog::getOpenFileContent`, in-memory database
  routing, etc.).

## Browser requirements

Qt6-wasm on this channel uses JSPI, which needs:

- Chrome 137+ (April 2025)
- Firefox 141+ (July 2025)
- Safari 18.4+ (April 2025)

## Current limitations

- **Continuous animation** — currently problematic and flaky. Qt-wasm
  timer-driven animation under JSPI can starve the browser main thread
  in the default configuration, so games and animated demos don't work
  reliably out of the box. This isn't a fundamental limitation — the
  path forward is likely a `requestAnimationFrame`-based tick source
  and better cooperation with the browser compositor — but it needs
  more work. Static and event-driven UIs (calculators, editors,
  viewers, form-based tools) are unaffected.
- **Dynamic side-module deps** (e.g. openblas as a runtime `.so`) — not
  yet supported. The runner only knows about the app's own artifacts.
- **Only `.tar.bz2`** — `.conda` format (zstd-inside-zip) would need
  additional decoders.
- **Limited Qt module coverage** — the emscripten-forge channel
  currently packages `qt6-main`, `qt6-svg`, `qt6-5compat`,
  `qt6-imageformats`, `qt6-webchannel`, `qt6-websockets` (each in both
  vanilla and `-jspi` variants). Notably **QML / QtQuick
  (`qt6-declarative`) is not yet packaged**, and neither are
  `qt6-charts`, `qt6-quick3d`, `qt6-multimedia`,
  `qt6-tools`, etc. Apps that use those modules need their recipes
  added to the channel first.

## Source

Runner source lives at
[`docs/qtapp/`](https://github.com/emscripten-forge/recipes/tree/main/docs/qtapp)
in this repo. Two files: `index.html` and `runner.js`. Deployed alongside
the rest of the docs via the existing MkDocs build (non-markdown files in
`docs/` are copied verbatim into the site).
