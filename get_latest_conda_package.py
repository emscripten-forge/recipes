import glob
import sys
import tarfile
import os
from os.path import expanduser
import stat
from shutil import copyfile
# Python program to find SHA256 hash string of a file
import hashlib
import tempfile

tmpdir = tempfile.gettempdir()

pkg_name = sys.argv[1].strip()

def sha256(fn):
    sha256_hash = hashlib.sha256()
    with open(fn, "rb") as f:
        # Read and update hash string value in blocks of 4K
        for byte_block in iter(lambda: f.read(4096),b""):
            sha256_hash.update(byte_block)
        digest = sha256_hash.hexdigest()
        with open(fn + ".sha256", "w") as fo:
            fo.write(digest)
    return digest

archs = ["linux-64", "osx-64", "win-64", "linux-aarch64", "osx-arm64"]
folder = expanduser("~/micromamba_pkgs/{arch}/")

def get_version_file(folder, pkg_name="micromamba"):
    mms = glob.glob(f'{folder}/{pkg_name}*')
    print("Folder: ", folder)
    print(mms)
    versions = []
    for m in mms:
        m = m[:-len('.tar.bz2')]  # remove tar.bz2 ending

        fpath, version, build = m.rsplit('-', 2)
        print(os.path.basename(fpath), pkg_name)
        if os.path.basename(fpath) != pkg_name:
            print("Skipping ... ", os.path.basename(fpath))
            continue

        build_num = int(build.rsplit('_', 1)[-1])
        versions.append((fpath, version, build_num, build))

    def assemble_file(v):
        return f"{v[0]}-{v[1]}-{v[3]}.tar.bz2"

    if not versions:
        return None

    # need to properly compare integers here!
    v = max(versions, key= lambda vx: [[int(vpart) for vpart in vx[1].split('.')]])

    print(assemble_file(v))

    return assemble_file(v), v[1]

found_archs = []
for arch in archs:
    vf = get_version_file(folder.format(arch=arch), pkg_name)
    if not vf:
        print(f"skipping {arch}")
        continue
    else:
        found_archs.append(arch)
        pkg_file, version = vf

    print(f"::set-output name={arch.replace('-', '_')}_pkg::{pkg_file}")
    if len(found_archs) == 1:
        print(f"::set-output name=micromamba_version::{version}")

    os.makedirs(os.path.join(tmpdir, f"micromamba-{arch}"), exist_ok=True)
    with tarfile.open(pkg_file, "r:bz2") as f:
        f.extractall(os.path.join(tmpdir, f"micromamba-{arch}/"))

for arch in found_archs:

    os.makedirs(os.path.join(tmpdir, f"micromamba-bins/{arch}/"), exist_ok=True)
    if arch.startswith("win"):
        outfile = os.path.join(tmpdir, f"micromamba-bins/{pkg_name}-{arch}.exe")
        copyfile(os.path.join(tmpdir, f"micromamba-{arch}/Library/bin/micromamba.exe"), outfile)
    else:
        outfile = os.path.join(tmpdir, f"micromamba-bins/{pkg_name}-{arch}")
        copyfile(os.path.join(tmpdir, f"micromamba-{arch}/bin/micromamba"), outfile)
        st = os.stat(outfile)
        os.chmod(outfile, st.st_mode | stat.S_IEXEC)

    outfile = outfile.replace('\\', '/')
    digest = sha256(outfile)
    print(f"::set-output name=micromamba_bin_{arch.replace('-', '_')}::{outfile}")
    print(f"::set-output name=micromamba_sha_{arch.replace('-', '_')}::{outfile}.sha256")
    print(f"::set-output name=micromamba_sha_val_{arch.replace('-', '_')}::{digest}")