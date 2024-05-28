---
date: 2024-05-24
category:
    - rust
    
authors:
    - derthorsten
    - wolfv
---

# Emscripten is now a proper package

So far, the emscripten package was a bit of a hack. It relied on a text file `~.emsdkdir` in the home directory which contained the directory of the emscripten installation. This was not very nice, because it was hard to build packages for several emscripten versions.

But now, emscripten is a repacked package that installs emscripten into the conda environment. This allows in principle to compile packages for multiple emscripten versions.
