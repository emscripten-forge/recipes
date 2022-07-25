
# TODO
# unvendor xsimd; use version packaged by conda-forge
# python -c "import os, shutil; shutil.rmtree(os.path.join('third_party', 'xsimd'))"
# python -c \"with open('setup.cfg', 'w') as s: s.write('[build_py]\\nno_xsimd=True')\"

python -m pip install . --no-deps -vv
