## Checklist for Adding Packages

### Pre-submission Checks
- [ ] Package requires building for `emscripten-wasm32` platform (not a noarch package), in other words, the package requires compilation.

### Recipe Structure
- [ ] Created directory: `recipes/recipes_emscripten/[package-name]/`
- [ ] Added `recipe.yaml` with proper structure:
  - [ ] `context` section with `version` (and optionally `name`)
  - [ ] `package` section with name and version using Jinja2 templates
  - [ ] `source` section with:
    - Source URL is valid and points to archive file (`.tar.gz`, `.tar.bz2`, `.tar.xz`, `.tgz`, or `.zip`)
    - Source URL contains `${{ version }}` template for version updates
    - SHA256 hash is correct (verified with `curl -sL <url> | sha256sum`)
    - Patches (if any) are included in `[package-name]/patches/` directory
  - [ ] `build` section with appropriate script/method
    - Python packages: `${PYTHON} -m pip install . ${PIP_ARGS}`
    - R packages: `$R CMD INSTALL $R_ARGS .`
    - C++ packages: Uses `emcmake`/`emmake` or `emconfigure`/`emmake`
    - Rust packages: Uses `rust-nightly` and `maturin` or appropriate Rust build tool
  - [ ] `requirements` section (build, host, run as needed)
  - [ ] `tests` section
    - Python packages: `test_import_[package].py` file created and referenced
    - C++ packages: Test executable or package_contents test
    - R packages: Package contents test
  - [ ] `about` section with license, homepage, summary

### Build Verification
- [ ] (Optional) Locally, recipe builds successfully:
  ```bash
  rattler-build build \
    --package-format tar-bz2 \
    -c https://repo.prefix.dev/emscripten-forge-4x \
    -c microsoft \
    -c conda-forge \
    --target-platform emscripten-wasm32 \
    --skip-existing none \
    -m variant.yaml \
    --recipe recipes/recipes_emscripten/[package-name]
  ```
- [ ] All tests pass


## Checklist for Updating Packages

- [ ] ⚠️ Bump build number if the version remains unchanged, or reset build number if updating the package to a newer version
- [ ] Tests pass

### PR Formatting
- [ ] PR title follows format: `Add [package-name]` or `Update [package-name] to [version]`
- [ ] PR description includes:
  - [ ] Package purpose/description
  - [ ] Version being added/updated
  - [ ] Any special build considerations or patches applied
  - [ ] (Optional) Test results summary

---

## Description
<!-- Provide a brief description of the package and why it's being added -->

## Package Details
- **Package Name**: 
- **Version**: 
- **Homepage**: 
- **License**: 

## Build Notes
<!-- Any special build considerations, patches applied, or issues encountered -->

## Test Results
<!-- Summary of test results -->
