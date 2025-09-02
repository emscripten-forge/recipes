# Emscripten-forge Recipes

Always follow these instructions first and fallback to search or additional exploration only when the information here is incomplete or found to be in error.

Emscripten-forge is a conda package repository for building packages targeting the `emscripten-wasm32` platform (WebAssembly). The repository contains 283+ package recipes and uses `pixi` for environment management and `rattler-build` for package building.

## Working Effectively

### Required Tools Installation
Install these tools in order before proceeding:

```bash
# Install pixi (package and environment manager)
curl -L https://github.com/prefix-dev/pixi/releases/latest/download/pixi-x86_64-unknown-linux-musl.tar.gz | tar -xzC /usr/local/bin

# Install micromamba (conda environment manager)  
curl -Ls https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-linux-64 -o micromamba && sudo mv micromamba /usr/local/bin/micromamba && sudo chmod +x /usr/local/bin/micromamba

# Verify installations
pixi --version
micromamba --version
```

### Environment Setup
Create the conda environment for emci tool:

```bash
# Create environment from ci_env.yml - takes 2-3 minutes
micromamba create -n emscripten-forge -f ci_env.yml --yes

# Verify emci tool works
micromamba run -n emscripten-forge python -m emci --help
```

### Building Packages

**CRITICAL**: Build commands take 30-60+ minutes. NEVER CANCEL builds - they require substantial time to complete.

#### First-Time Setup (Required Once)
```bash
# NEVER CANCEL: Build compiler packages - takes 45-60+ minutes. Set timeout to 90+ minutes.
pixi run setup
```
This builds: emscripten compiler, cross-python, and pytester packages required for subsequent builds.

#### Building Individual Packages
```bash
# Build a specific emscripten-wasm32 package - takes 15-45+ minutes. NEVER CANCEL. Set timeout to 60+ minutes.
pixi run build-emscripten-wasm32-pkg recipes/recipes_emscripten/[PACKAGE_NAME]

# Example: Build zarr package
pixi run build-emscripten-wasm32-pkg recipes/recipes_emscripten/zarr
```

#### Building Changed Packages (CI-style)
```bash
# Build packages with changes using emci tool - takes 30-90+ minutes. NEVER CANCEL.
micromamba run -n emscripten-forge python -m emci build changed /path/to/repo origin/main HEAD
```

### Documentation

#### Build Documentation
```bash
# Build static documentation - takes ~7 seconds
pixi run docs-build
# Output in site/ directory
```

#### Serve Documentation Locally  
```bash
# Serve documentation on http://127.0.0.1:8000 - starts immediately
pixi run docs-serve
# Stop with Ctrl+C
```

### Validation Steps
After making any changes to recipes:

1. **ALWAYS** build and test the specific package you modified
2. **ALWAYS** run `pixi run docs-build` to verify documentation builds without errors  
3. **ALWAYS** validate your recipe follows the format in `docs/development/recipe_format.md`
4. Check build logs carefully for emscripten-specific linking issues (see troubleshooting)

## Common Tasks

### Repository Structure
```
recipes/
├── recipes/           # Host platform recipes (emscripten compiler, cross-python, etc.)  
├── recipes_emscripten/ # 283+ emscripten-wasm32 target packages
docs/                  # Documentation source
.github/workflows/     # CI build automation
pixi.toml             # Task definitions and environments
variant.yaml          # Build configuration and package pins
ci_env.yml            # Conda environment for emci tool
```

### Key Directories and Files
- `recipes/recipes_emscripten/` - All WebAssembly package recipes (283+ packages)
- `docs/development/` - Developer guides for adding packages, local builds, troubleshooting
- `pixi.toml` - Defines all build tasks and environment configurations
- `variant.yaml` - Pin versions, compiler configurations, build variants
- `.github/workflows/build_recipes.yaml` - CI pipeline that builds changed recipes

### Available pixi Tasks
```bash
# List all available tasks
pixi task list

# Key tasks:
# setup - Build compiler packages (45-60+ minutes)
# build-emscripten-wasm32-pkg - Build specific package (15-45+ minutes)  
# docs-build - Build documentation (~7 seconds)
# docs-serve - Serve documentation locally
```

### Package Types and Examples
The repository supports multiple package types:

**Python packages**: zarr, numpy, scipy, matplotlib, pandas, etc.
- Use `cross-python_${{ target_platform }}` build requirement
- Example: `recipes/recipes_emscripten/zarr/`

**C/C++ packages**: boost-cpp, arrow-cpp, opencv, etc.  
- Use `emcmake` instead of `cmake`, `emmake` instead of `make`
- Example: `recipes/recipes_emscripten/boost-cpp/`

**Rust packages**: cryptography, pydantic-core, etc.
- Use `maturin` for PyO3 packages
- Pin `cffi == 1.15.1` during transition period

### Testing
Package tests are defined in recipe.yaml files:
```yaml
tests:
- script: pytester
  files:
    recipe:
    - test_import_[package].py
```

Most tests are simple import tests. Tests run automatically during package builds.

## Validation Scenarios  

**After modifying a recipe**:
1. Run `pixi run build-emscripten-wasm32-pkg recipes/recipes_emscripten/[package]` (NEVER CANCEL - 15-45+ minutes)
2. Verify package builds successfully and tests pass
3. Check for emscripten-specific warnings in build logs

**After modifying documentation**:
1. Run `pixi run docs-build` (~7 seconds)  
2. Run `pixi run docs-serve` and verify changes at http://127.0.0.1:8000
3. Check for broken links or formatting issues

## Timing Expectations and Timeouts

**NEVER CANCEL BUILDS OR TESTS** - Use these minimum timeout values:

- `pixi run setup`: 90+ minutes (builds compiler packages)
- `pixi run build-emscripten-wasm32-pkg`: 60+ minutes (individual packages)
- `emci build changed`: 120+ minutes (multiple packages)
- `pixi run docs-build`: 30 seconds
- `pixi run docs-serve`: starts immediately

## Common Issues and Troubleshooting

### Build Failures
```bash
# Network timeouts during package downloads
# SOLUTION: Retry the command, builds are resumable

# Missing dependencies  
# SOLUTION: Check variant.yaml for correct package pins
# SOLUTION: Verify requirements in recipe.yaml match available packages
```

### Runtime Errors in Built Packages
```bash
# "PyLong_FromLongLong: imported function does not match expected type"
# SOLUTION: Add linker flag "-s WASM_BIGINT" to package build script
```

### Development Workflow
```bash
# Check what changed
git diff origin/main

# Build only changed packages
micromamba run -n emscripten-forge python -m emci build changed . origin/main HEAD

# Add new package
# 1. Create directory: recipes/recipes_emscripten/[new-package]/
# 2. Add recipe.yaml following examples in docs/development/adding_packages.md
# 3. Add test file: test_import_[package].py  
# 4. Build: pixi run build-emscripten-wasm32-pkg recipes/recipes_emscripten/[new-package]
```

## Reference Documentation

**ALWAYS** consult these docs when working with recipes:
- `docs/development/local_builds.md` - Detailed build instructions
- `docs/development/adding_packages.md` - Package creation guide with examples
- `docs/development/recipe_format.md` - Recipe format specification  
- `docs/development/troubleshooting.md` - Common issues and solutions

The online documentation is available at https://emscripten-forge.org with comprehensive guides for all package types.

## Network Requirements

All build commands require internet access to:
- Download source packages from PyPI, GitHub, etc.
- Access conda channels (conda-forge, emscripten-forge-dev, microsoft)
- Fetch build dependencies

Builds will fail with network timeouts in restricted environments.