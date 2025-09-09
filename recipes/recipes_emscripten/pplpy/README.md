# pplpy Recipe for emscripten-wasm32

## Status: Work in Progress

This recipe provides pplpy (Python interface to the Parma Polyhedra Library) for emscripten-wasm32.

## Current Issues

The recipe is currently **skipped** for emscripten-wasm32 due to missing dependencies:

### Required Dependencies Not Yet Available:

1. **PPL (Parma Polyhedra Library)** - A C++ library for manipulating convex polyhedra
   - Needs to be compiled for WebAssembly/emscripten
   - Headers required: `ppl.hh`
   - Libraries required: `libppl`

2. **cysignals** - Python package for interrupt and signal handling in Cython
   - May need WebAssembly-specific adaptations due to limited signal support
   - Required at both build and runtime

### Available Dependencies:

✅ **gmpy2** - Available in emscripten-forge  
✅ **cffi** - Available in emscripten-forge  
✅ **cython** - Available as build dependency  

## Next Steps

To complete this recipe, the following work is needed:

1. **Create PPL recipe** for emscripten-wasm32
   - Port PPL C++ library to WebAssembly
   - Handle any emscripten-specific compilation issues
   
2. **Create cysignals recipe** for emscripten-wasm32  
   - May require WebAssembly-specific patches
   - Signal handling limitations may need workarounds
   
3. **Update this recipe**
   - Remove `skip: true` line
   - Add PPL and cysignals as dependencies
   - Test compilation and functionality

## Package Information

- **Source**: pplpy 0.8.10 from PyPI
- **License**: GPL-3.0
- **Homepage**: https://github.com/sagemath/pplpy
- **Description**: Python wrapper for the Parma Polyhedra Library (PPL)

## Testing

Basic import test is provided in `test_import_pplpy.py` which will verify:
- Package can be imported
- Basic PPL classes are available
- Simple polyhedron operations work