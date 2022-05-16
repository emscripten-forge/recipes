from bitfurnace.make import Make
from bitfurnace.cmake import CMake
from bitfurnace.util import variables

import shutil
import glob
import os
from pathlib import Path

def install(from_path, to_path, follow_symlinks=False):
    fp = str(from_path)
    tp = str(to_path)

    to_path.mkdir(parents=True, exist_ok=True)

    if '*' in fp:
        for f in glob.glob(fp):
            shutil.copy(f, tp, follow_symlinks=follow_symlinks)
    else:
        shutil.copy(fp, tp, follow_symlinks=follow_symlinks)

class UnixRecipe(Make):

    def get_install_args(self):
        return self.default_install_args + self.install_args

    def install(self):
        run(['make', 'install'] + self.get_install_args())
        if not features.static and not target_platform.startswith('emscripten'):
            if target_platform.startswith('linux') or target_platform.startswith('emscripten'):
                run(['make', '-f', 'Makefile-libbz2_so'] + self.get_install_args())
                install(f'libbz2.so.{pkg_version}', prefix / 'lib')
                Path(prefix / 'lib' / 'libbz2.so').symlink_to(prefix / 'lib' / f'libbz2.so.{pkg_version}')
            else:
                run([cc] + f'-shared -Wl,-install_name -Wl,libbz2.dylib -o libbz2.{pkg_version}.dylib blocksort.o huffman.o crctable.o randtable.o compress.o decompress.o bzlib.o'.split())

                install(f'libbz2.{pkg_version}.dylib', prefix / 'lib')
                Path(prefix / 'lib' / 'libbz2.dylib').symlink_to(prefix / 'lib' / f'libbz2.{pkg_version}.dylib')

            Path(prefix / 'lib' / 'libbz2.a').unlink()

    def __init__(self):
        self.cflags += ['-Wall', '-Winline', '-O2', '-g', '-D_FILE_OFFSET_BITS=64', '-fPIC']

        cflags = ' '.join(self.cflags)
        self.build_args = [f'CFLAGS={cflags}']
        self.install_args = [f'CFLAGS={cflags}']



class CMakeRecipe(CMake):
    # cmakelists_dir = variables.recipe_dir
    pass

if target_platform.startswith('win'):
    pass
elif target_platform.startswith('emscripten'):
    shutil.copy2(os.path.join( variables.recipe_dir, "CMakeLists.txt"), variables.src_dir)
    Recipe = CMakeRecipe
else:
    Recipe = UnixRecipe
