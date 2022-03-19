import logging
import subprocess
from os import chdir
from pathlib import Path


def getName_andTag(pkg):
    name, version, hash = pkg.rsplit("-", 2)

    tag = version + "-" + hash
    tag_resized = tag.rpartition(".tar")[0]
    tag_resized = tag_resized.replace("_", "-")

    return name, tag_resized


def install_on_OS():
    logging.warning("Installing oras on the system...")
    subprocess.run(
        "curl -LO https://github.com/oras-project/oras/releases/download/v0.12.0/oras_0.12.0_darwin_amd64.tar.gz",
        shell=True,
    )
    location = Path("oras-install")
    location.mkdir(mode=511, parents=False, exist_ok=True)
    subprocess.run("tar -zxf oras_0.12.0_*.tar.gz -C oras-install/", shell=True)
    subprocess.run("mv oras-install/oras /usr/local/bin/", shell=True)
    subprocess.run("rm -rf oras_0.12.0_*.tar.gz oras-install/", shell=True)


class Oras:
    def __init__(self, github_owner, user_token, origin, system):
        self.owner = github_owner
        self.conda_prefix = origin
        self.token = user_token
        self.strSys = str(system)
        logging.warning(f"Host is <<{self.strSys}>>")
        if "osx" in self.strSys:
            install_on_OS()

    def login(self):
        loginStr = f"echo {self.token} | oras login https://ghcr.io -u {self.owner} --password-stdin"
        subprocess.run(loginStr, shell=True)

    def push(self, target, data):
        strData = str(data)
        pkg = str(data).rsplit("/", 1)[-1]
        length = len(strData) - len(pkg)
        path = strData[:length]
        pkg_name, tag = getName_andTag(pkg)
        origin = "./" + pkg

        # upload the tar_bz2 file to the right url
        push_bz2 = f"oras push ghcr.io/{self.owner}/samples/{target}/{pkg_name}:{tag} {origin}:application/octet-stream"
        push_bz2_latest = f"oras push ghcr.io/{self.owner}/samples/{target}/{pkg_name}:latest {origin}:application/octet-stream"
        upload_url = f"ghcr.io/{self.owner}/samples/{target}/{pkg_name}:{tag}"
        logging.warning(f"Cmd <<{push_bz2}>>")
        logging.warning(f"Latest Cmd <<{push_bz2_latest}>>")
        chdir(path)

        logging.warning(
            f"Uploading <<{pkg}>>. path <<{origin} (from dir: << {self.conda_prefix} >> to link: <<{upload_url}>>"
        )
        subprocess.run(push_bz2, shell=True)
        subprocess.run(push_bz2_latest, shell=True)
        logging.warning(f"Package <<{pkg_name}>> uploaded to: <<{upload_url}>>")

    def pull(self, pkg, tag, dir):
        pullCmd = f'oras pull ghcr.io/{self.owner}/samples/{self.strSys}/{pkg}:{tag} --output {dir} -t "application/octet-stream"'

        logging.warning(f"Pulling lattest of  <<{pkg}>>. with command: <<{pullCmd}>>")
        subprocess.run(pullCmd, shell=True)
        logging.warning(f"Latest version of  <<{pkg}>> pulled")
