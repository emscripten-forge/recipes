## Template A: Checklist for **adding** a package

### Pre-submission Checks
- [ ] Package requires building for `emscripten-wasm32` platform (not a noarch package), in other words, the package requires compilation.

<!-- If you have a noarch package, we suggest submitting your recipe to https://github.com/conda-forge/staged-recipes/ instead. -->

### Recipe Structure
Added `recipes/recipes_emscripten/[package-name]/recipe.yaml` with proper structure:
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
  - Build number is 4000
  - If the script is longer than 3 lines, a *build.sh* is included
- [ ] `requirements` section (build, host, run as needed)
- [ ] `tests` section
  - Python packages: `test_import_[package].py` file created and referenced
  - C++ packages: Test executable or package_contents test
  - R packages: Package contents test
- [ ] `about` section with license, homepage, summary

#### About the build number

We follow the following scheme:
- Emscripten 3.x builds have build numbers >=0,<1000
- Emscripten 4.x builds have build numbers >=4000,<5000 (the current `main` branch)
- Future Emscripten 5.x builds will have build numbers >=5000,<6000
- etc

---

## Template B: Checklist for **updating** a package

- [ ] ⚠️ Bump build number if the version remains unchanged
- [ ] Or reset build number to 4000 if updating the package to a newer version

---

## PR Formatting
- [ ] PR title follows format: `Add [package-name]` or `Update [package-name] to [version]`
- [ ] PR description includes:
  - Version being added/updated
  - Any special build considerations or patches applied

## Package Details
- **Package Name**:
- **Version**:

## Build Notes
<!-- Any special build considerations, patches applied, or issues encountered -->

