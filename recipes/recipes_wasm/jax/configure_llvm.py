"""Bazel imports for an installed LLVM/MLIR distribution.

Core libraries and generated headers come exclusively from the prefix. Only
JAX's namespace-specific Python binding glue is compiled from installed sources.
The original Bazel overlay is used for target names and TableGen rule definitions,
not as an LLVM/MLIR source or library provider.
"""

import argparse
import ast
import json
from pathlib import Path
import re
import shutil


def link(source, destination):
    if not source.exists():
        raise FileNotFoundError(source)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.symlink_to(source, target_is_directory=source.is_dir())


def export_targets(prefix):
    targets = {}
    for path in (prefix / "lib/cmake").glob("*/*Exports.cmake"):
        targets.update(read_targets(path))
    for path in (prefix / "lib/cmake").glob("*/*Targets.cmake"):
        targets.update(read_targets(path))
    return targets


def read_targets(path):
    result = {}
    text = path.read_text()
    for target, body in re.findall(
        r"set_target_properties\((\w+) PROPERTIES\s+(.*?)\n\)", text, re.S
    ):
        match = re.search(r'INTERFACE_LINK_LIBRARIES "(.*?)"', body, re.S)
        if match:
            result[target] = match.group(1).split(";")
    return result


def declarations(path):
    result = []
    for statement in ast.parse(path.read_text()).body:
        if not isinstance(statement, ast.Expr) or not isinstance(statement.value, ast.Call):
            continue
        call = statement.value
        fields = {kw.arg: kw.value for kw in call.keywords}
        name = fields.get("name")
        if isinstance(name, ast.Constant):
            result.append((name.value, ast.unparse(call.func), fields))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prefix", type=Path, required=True)
    parser.add_argument("--native-prefix", type=Path, required=True)
    parser.add_argument("--overlay", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--runtime-sources", type=Path, required=True)
    parser.add_argument("--python-version", default="3.14")
    args = parser.parse_args()
    prefix, native, overlay, output = [
        p.resolve() for p in (args.prefix, args.native_prefix, args.overlay, args.output)
    ]
    config = (prefix / "include/llvm/Config/llvm-config.h").read_text()
    for macro, value in (("LLVM_VERSION_MAJOR", "23"), ("LLVM_VERSION_MINOR", "1"),
                         ("LLVM_VERSION_PATCH", "2"), ("LLVM_ENABLE_THREADS", "0")):
        if not re.search(rf"^#define {macro} {value}$", config, re.M):
            raise RuntimeError(f"Expected {macro}={value} in installed LLVM")
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    (output / "WORKSPACE.bazel").write_text('workspace(name="llvm-project")\n')
    (output / "MODULE.bazel").write_text('module(name="llvm-project")\n')
    link(prefix / "lib", output / "target_lib")
    link(native / "lib", output / "native_lib")
    link(native / "bin", output / "native_bin")
    link(prefix / "include", output / "target_include")
    link(native / "include", output / "native_include")
    for component in ("llvm", "mlir", "lld"):
        (output / component).mkdir()
        link(prefix / "include", output / component / "include")

    # The MLIR distribution installs reconfigurable Python binding sources.
    binding_dir = output / "mlir/lib/Bindings/Python"
    for group in (prefix / "src/python").glob("MLIRPythonExtension.*"):
        for source in group.glob("*"):
            if source.suffix in (".cpp", ".h"):
                destination = binding_dir / source.name
                if not destination.exists():
                    link(source, destination)

    (output / "mlir/tblgen.bzl").write_text((overlay / "mlir/tblgen.bzl").read_text())
    for name in ("CRunnerUtils.cpp", "Float16bits.cpp"):
        link(args.runtime_sources.resolve() / name, output / "mlir/runtime" / name)
    (output / "tools.bzl").write_text('''
def _installed_binary_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output=out, target_file=ctx.file.binary, is_executable=True)
    return [DefaultInfo(executable=out, runfiles=ctx.runfiles(files=[ctx.file.binary]))]
installed_binary = rule(implementation=_installed_binary_impl,
    attrs={"binary": attr.label(allow_single_file=True)}, executable=True)
''')
    libraries = {p.stem[3:]: p for p in (prefix / "lib").glob("*.a")}
    native_libraries = {p.stem[3:]: p for p in (native / "lib").glob("*.a")}
    dependencies = export_targets(prefix)
    aliases = {
        "AllocationOpInterface": "MLIRBufferizationDialect", "ShapeTransforms": "MLIRShapeOpsTransforms", "CAPICF": "MLIRCAPIControlFlow", "FileCheckLib": "LLVMFileCheck", "ObjCARC": "LLVMObjCARCOpts",
        "Scalar": "LLVMScalarOpts", "IPO": "LLVMipo", "DebugInfo": "LLVMDebugInfoDWARF",
        "BitstreamWriter": "LLVMBitstreamReader", "FuncExtensions": "MLIRFuncAllExtensions",
        "ToLLVMIRTranslation": "MLIRTargetLLVMIRExport",
        "FromLLVMIRTranslation": "MLIRTargetLLVMIRImport",
        "QuantOps": "MLIRQuantDialect", "CallOpInterfaces": "MLIRCallInterfaces",
        "InliningUtils": "MLIRTransformUtils", "ComplexCommon": "MLIRComplexDivisionConversion",
        "LLVMIRTransformsLegalizeForExport": "MLIRLLVMIRTransforms",
        "LLVMIRTransformsDIExpressionLegalization": "MLIRLLVMIRTransforms",
        # Bazel's VectorToLLVM combines patterns and the pass. CMake splits
        # them; the pass target already depends on the patterns archive.
        "VectorToLLVM": "MLIRVectorToLLVMPass",
        "mlir_c_runner_utils": "mlir_c_runner_utils",
        "mlir_runner_utils": "mlir_runner_utils",
        "_mlir_c_runner_utils": "mlir_c_runner_utils",
        "_mlir_runner_utils": "mlir_runner_utils",
    }
    header = '''load("@rules_cc//cc:defs.bzl", "cc_import", "cc_library")
load("//:tools.bzl", "installed_binary")
package(default_visibility=["//visibility:public"])
config_setting(name="wasm", constraint_values=["@platforms//os:emscripten"])
'''
    root = [header, 'exports_files(glob(["target_lib/*.a", "native_lib/*.a", "native_lib/*.dylib", "native_bin/*"]))\n']
    native_support = []
    for name, stem in (("native_z", "z"), ("native_zstd", "zstd")):
        candidates = [native / "lib" / f"lib{stem}{suffix}"
                      for suffix in (".so", ".so.1", ".dylib", ".1.dylib", ".a")]
        library = next((p for p in candidates if p.exists()), None)
        if library is None:
            raise RuntimeError(f"Missing native {stem} library in {native}")
        field = "static_library" if library.suffix == ".a" else "shared_library"
        root.append(f'cc_import(name="{name}", {field}="native_lib/{library.name}")\n')
        native_support.append(":" + name)
    root.append('cc_library(name="headers", hdrs=select({":wasm": glob(["target_include/**/*.h", "target_include/**/*.inc", "target_include/**/*.def"]), "//conditions:default": glob(["native_include/**/*.h", "native_include/**/*.inc", "native_include/**/*.def"])}), includes=select({":wasm": ["target_include"], "//conditions:default": ["native_include"]}))\n')
    for name, library in sorted(libraries.items()):
        root.append(f'cc_import(name="{name}_target", static_library="target_lib/{library.name}")\n')
        native_library = native_libraries.get(name)
        if native_library:
            root.append(f'cc_import(name="{name}_native", static_library="native_lib/{native_library.name}")\n')
            imports = f'select({{":wasm": [":{name}_target"], "//conditions:default": [":{name}_native"]}})'
        else:
            imports = f'[":{name}_target"]'
        deps = []
        for dep in dependencies.get(name, []):
            dep = re.sub(r"\$<LINK_ONLY:([^>]+)>", r"\1", dep)
            if dep in libraries and dep != name:
                deps.append(":" + dep)
            elif dep == "ZLIB::ZLIB" and "z" in libraries:
                deps.append(":z")
        extra = ''
        if name == "LLVMSupport":
            extra = '+select({":wasm": [], "//conditions:default": ' + json.dumps(native_support) + '})'
        root.append(f'cc_library(name={json.dumps(name)}, deps={imports}+{json.dumps([":headers"]+sorted(set(deps)))}{extra})\n')
    (output / "BUILD.bazel").write_text("".join(root))
    missing = {}
    for component, library_prefix in (("llvm", "LLVM"), ("mlir", "MLIR"), ("lld", "lld")):
        lines = [header]
        lines.append('load("//mlir:tblgen.bzl", "td_library")\n')
        lines.append('cc_library(name="installed_headers", hdrs=glob(["include/**/*.h", "include/**/*.inc", "include/**/*.def"]), includes=["include"])\n')
        lines.append('exports_files(glob(["include/**/*.td", "lib/Bindings/Python/*.cpp", "lib/Bindings/Python/*.h"]))\n')
        missing[component] = []
        declared = {"wasm", "installed_headers"}
        for name, kind, fields in declarations(overlay / component / "BUILD.bazel"):
            if name in ("llvm-tblgen", "mlir-tblgen", "mlir-pdll"):
                if (native / "bin" / name).exists():
                    lines.append(f'installed_binary(name="{name}", binary="//:native_bin/{name}")\n')
                    declared.add(name)
                continue
            candidate = aliases.get(name, library_prefix + name)
            if component == "mlir" and name == "CAPIIR":
                lines.append('cc_library(name="CAPIIR", deps=["//:MLIRCAPIIR", "//:MLIRCAPIFunc", "//:MLIRCAPIIRDL"])\n')
                declared.add(name)
            elif candidate in libraries:
                lines.append(f'alias(name={json.dumps(name)}, actual="//:{candidate}")\n')
                declared.add(name)
            elif kind in ("gentbl_cc_library", "gentbl_filegroup", "td_library", "filegroup"):
                if kind == "td_library":
                    lines.append(f'td_library(name={json.dumps(name)}, srcs=glob(["include/**/*.td"]), includes=["include"])\n')
                elif kind == "filegroup":
                    lines.append(f'filegroup(name={json.dumps(name)}, srcs=glob(["include/**/*.td", "include/**/*.h", "include/**/*.inc"]))\n')
                else:
                    lines.append(f'alias(name={json.dumps(name)}, actual=":installed_headers")\n')
                declared.add(name)
            elif kind == "cc_library":
                strings = [node.value for node in ast.walk(fields.get("srcs", ast.List(elts=[]))) if isinstance(node, ast.Constant) and isinstance(node.value, str)]
                if name.startswith("MLIRBindingsPython"):
                    continue
                if not any(x.endswith((".cpp", ".cc", ".c")) for x in strings):
                    lines.append(f'alias(name={json.dumps(name)}, actual=":installed_headers")\n')
                    declared.add(name)
                else:
                    missing[component].append(name)
        # Backend targets in LLVM's overlay are declared by a loop, not as
        # individual AST calls. Export every installed component as well.
        for library in sorted(libraries):
            if library.startswith(library_prefix):
                name = library[len(library_prefix):]
                if name not in declared:
                    lines.append(f'alias(name={json.dumps(name)}, actual="//:{library}")\n')
                    declared.add(name)
        if component == "mlir":
            for library in sorted(libraries):
                if library.startswith("MLIRCAPI"):
                    name = library[len("MLIR"):]
                    for suffix in ("Headers", "Objects"):
                        if name + suffix not in declared:
                            actual = ":installed_headers" if suffix == "Headers" else "//:" + library
                            lines.append(f'alias(name="{name}{suffix}", actual="{actual}")\n')
                            declared.add(name + suffix)
        if component == "mlir":
            lines.append('''cc_library(name="mlir_c_runner_utils",
    srcs=["runtime/CRunnerUtils.cpp", "runtime/Float16bits.cpp"],
    deps=[":installed_headers", "//llvm:Support"], copts=["-fno-rtti"])
''')
            for name in ("MLIRBindingsPythonNanobindHeaders", "MLIRBindingsPythonNanobindHeadersAndDeps", "MLIRBindingsPythonHeaders", "MLIRBindingsPythonHeadersAndDeps"):
                lines.append(f'cc_library(name="{name}", deps=[":installed_headers", ":CAPIIR", ":CAPIDebug", ":CAPITransforms", "@nanobind", "@rules_python//python/cc:current_py_cc_headers"])\n')
            lines.append('''cc_library(name="MLIRBindingsPythonCore",
    srcs=glob(["lib/Bindings/Python/Globals.cpp", "lib/Bindings/Python/IR*.cpp", "lib/Bindings/Python/Pass.cpp", "lib/Bindings/Python/Rewrite.cpp"]),
    hdrs=glob(["lib/Bindings/Python/*.h"]), includes=["lib/Bindings/Python"],
    copts=["-fexceptions", "-frtti"],
    deps=[":CAPIIR", ":CAPIAsync", ":CAPIDebug", ":CAPIInterfaces", ":CAPITransforms", ":Support", ":MLIRBindingsPythonNanobindHeaders", "@nanobind", "@rules_python//python/cc:current_py_cc_headers"])
''')
        (output / component / "BUILD.bazel").write_text("".join(lines))
    # JAX repackages these Python files into jaxlib.mlir; use the installed
    # generated files instead of regenerating upstream MLIR dialect wrappers.
    python_package = prefix / f"lib/python{args.python_version}/site-packages/mlir"
    python_dir = output / "mlir/python"
    link(python_package, python_dir / "mlir")
    python_lines = ['package(default_visibility=["//visibility:public"])\n']
    for name, kind, fields in declarations(overlay / "mlir/python/BUILD.bazel"):
        files = []
        if kind == "gentbl_filegroup":
            try:
                files = list(ast.literal_eval(fields["tbl_outs"]))
            except (KeyError, ValueError):
                continue
        elif kind == "filegroup":
            node = fields.get("srcs")
            if isinstance(node, ast.List):
                files = [x.value for x in node.elts if isinstance(x, ast.Constant)]
            elif isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == "glob":
                for pattern in ast.literal_eval(node.args[0]):
                    files.extend("mlir/" + str(p.relative_to(python_package))
                                 for p in python_package.glob(pattern.removeprefix("mlir/")))
        else:
            continue
        files = [f for f in files if f.startswith(":") or (python_dir / f).exists()]
        python_lines.append(f'filegroup(name={json.dumps(name)}, srcs={json.dumps(files)})\n')
    (python_dir / "BUILD.bazel").write_text("".join(python_lines))
    (output / "manifest.json").write_text(json.dumps({
        "prefix": str(prefix), "native_prefix": str(native), "libraries": sorted(libraries),
        "unmapped_overlay_targets": missing,
        "core_compilation": False,
    }, indent=2) + "\n")
    print(f"Imported {len(libraries)} archives from {prefix}")
    print("Unmapped overlay targets:", {k: len(v) for k, v in missing.items()})


if __name__ == "__main__":
    main()
