from ensurepip import version
from conda_oci_mirror.oci import OCI
import pathlib
from pprint import pprint
from conda_oci_mirror.layer import Layer
from conda_oci_mirror.oci_mirror import upload_conda_package
#def upload_conda_package(path_to_archive, host, channel, oci, extra_tags=None):
import sys

dot_data_file_media_type = "vnd.emscript.data"
dot_js_file_media_type = "application/js"

def extract_name_version_build(full_pkg):
    print(f"full_pkg: {full_pkg}")
    pkg_fullname = full_pkg.rsplit("/", -1)[-1]
    print (f"pkg_fullname: {pkg_fullname}")
    name_and_version = pkg_fullname[0:-8]
    print (f"name_and_version: {name_and_version}")
    name, version, build = name_and_version.rsplit("-",2)

    return [name, f"{version}-{build}"]


def push_new_layers(oci, prefix, pkg_name, pkg_version_and_build):
    files_location = "/home/runner/packed"
    upload_name = prefix + pkg_name
    old_manifest = oci.get_manifest(upload_name, pkg_version_and_build)

    js_fn = f"{files_location}/{pkg_name}-{pkg_version_and_build}.js"
    data_fn = f"{files_location}/{pkg_name}-{pkg_version_and_build}.data"


    for layer in old_manifest["layers"]:
        if layer["mediaType"] == dot_js_file_media_type:
            print("Already a JS file pushed for this artifact.")
            return

    new_layers = [
        Layer(pathlib.Path(js_fn), dot_js_file_media_type), 
        Layer(pathlib.Path(data_fn), dot_data_file_media_type)
    ]

    oci.push_image(upload_name, pkg_version_and_build, new_layers, old_manifest=old_manifest)

if __name__ == "__main__":
    # total arguments
    args_len = len(sys.argv)

    if args_len < 5:
        print(f"expecting 4 arguments but only {args_len} were provided")
    else:
        user_or_org = sys.argv[1]
        host = f"https://ghcr.io"
        conda_prefix = sys.argv[2]
        channel = sys.argv[3]
        subdir = sys.argv[4]
        new_oci = OCI(host, user_or_org)

        remote_loc = f"ghcr.io/{user_or_org}"
        base_dir = f"{str(conda_prefix)}/{channel}/{subdir}"
        #for child in p.iterdir()
        for path in pathlib.Path(base_dir).iterdir():
            path_to_archive = str (path)
            if path.is_file() and path_to_archive.endswith(".tar.bz2"):
                pkg_name, pkg_version_and_build = extract_name_version_build (path_to_archive)

                #push image
                print (f"?????????????????????????path is: {path_to_archive}")
                print (f"?????????????????????????remote loc is: {remote_loc}")
                print (f"?????????????????????????channel is: {channel}")
                print (f"?????????????????????????OCI location: {new_oci.location}")
                print (f"?????????????????????????OCI user: {new_oci.user_or_org}")
                upload_conda_package(path_to_archive, remote_loc, channel, new_oci)

                print(f"File uploaded to {remote_loc}")
                #add layers
                push_new_layers(new_oci, f"{channel}/{subdir}/", pkg_name, pkg_version_and_build)

                #print the manifest
                m = new_oci.get_manifest(f"{channel}/{subdir}/{pkg_name}", pkg_version_and_build)
                pprint(m)