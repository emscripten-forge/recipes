## Template A: Checklist for **adding** a package

### Pre-submission Checks
- [ ] Package requires building for `emscripten-wasm32` platform (not a noarch package), in other words, the package requires compilation.

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
  - Build number is 0
  - If the script is longer than 3 lines, a *build.sh* is included
- [ ] `requirements` section (build, host, run as needed)
- [ ] `tests` section
  - Python packages: `test_import_[package].py` file created and referenced
  - C++ packages: Test executable or package_contents test
  - R packages: Package contents test
- [ ] `about` section with license, homepage, summary

---

## Template B: Checklist for **updating** a package

- [ ] ⚠️ Bump build number if the version remains unchanged
- [ ] Or reset build number to 0 if updating the package to a newer version

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

