# License: BSD3
# Modified from https://github.com/regro/cf-scripts
# Original License:
# BSD 3-clause license
# Copyright (c) 2015-2018, NumFOCUS
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Tick-my-feedstocks
# Copyright (c) 2017, Peter M. Landwehr
#
# Rever
# Copyright (c) 2017, Anthony Scopatz
#
# Doctr
# The MIT License (MIT)
# Copyright (c) 2016 Aaron Meurer, Gil Forsyth
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
from contextlib import contextmanager
import abc, re, copy
import feedparser, subprocess
import collections.abc
from typing import Optional, List, cast, Iterator, Set
from conda.models.version import VersionOrder

import ruamel, jinja2, requests, time, hashlib, math, functools
from ruamel.yaml import YAML
from collections import OrderedDict
from multiprocessing import Process, Pipe
from ruamel.yaml.representer import RoundTripRepresenter

RECIPE_FIELD_ORDER = [
    "context",
    "package",
    "source",
    "build",
    "requirements",
    "test",
    "features",
    "app",
    "outputs",
    "about",
    "extra",
]

class MyRepresenter(RoundTripRepresenter):
    pass

ruamel.yaml.add_representer(
    OrderedDict, MyRepresenter.represent_dict, representer=MyRepresenter
)

class AbstractSource(abc.ABC):
    name: str

    @abc.abstractmethod
    def get_version(self, url: str) -> Optional[str]:
        pass

    @abc.abstractmethod
    def get_url(self, meta_yaml) -> Optional[str]:
        pass

def _split_alpha_num(ver: str) -> List[str]:
    for i, c in enumerate(ver):
        if c.isalpha():
            return [ver[0:i], ver[i:]]
    return [ver]

def next_version(ver: str, increment_alpha: bool = False) -> Iterator[str]:
    ver_split = []
    ver_dot_split = ver.split(".")
    n_dot = len(ver_dot_split)
    for idot, sdot in enumerate(ver_dot_split):

        ver_under_split = sdot.split("_")
        n_under = len(ver_under_split)
        for iunder, sunder in enumerate(ver_under_split):

            ver_dash_split = sunder.split("-")
            n_dash = len(ver_dash_split)
            for idash, sdash in enumerate(ver_dash_split):

                for el in _split_alpha_num(sdash):
                    ver_split.append(el)

                if idash < n_dash - 1:
                    ver_split.append("-")

            if iunder < n_under - 1:
                ver_split.append("_")

        if idot < n_dot - 1:
            ver_split.append(".")

    for k in reversed(range(len(ver_split))):
        try:
            t = int(ver_split[k])
            is_num = True
        except Exception:
            is_num = False

        if is_num:
            ver_split[k] = str(t + 1)
            yield "".join(ver_split)
            ver_split[k] = "0"
        elif increment_alpha and ver_split[k].isalpha() and len(ver_split[k]) == 1:
            ver_split[k] = chr(ord(ver_split[k]) + 1)
            yield "".join(ver_split)
            ver_split[k] = "a"
        else:
            continue

def url_exists(url: str) -> bool:
    try:
        output = subprocess.check_output(
            ["wget", "--spider", url],
            stderr=subprocess.STDOUT,
            timeout=1,
        )
    except Exception:
        return False
    # For FTP servers an exception is not thrown
    if "No such file" in output.decode("utf-8"):
        return False
    if "not retrieving" in output.decode("utf-8"):
        return False

    return True


def url_exists_swap_exts(url: str):
    if url_exists(url):
        return True, url

    # TODO this is too expensive
    # from conda_forge_tick.url_transforms import gen_transformed_urls
    # for new_url in gen_transformed_urls(url):
    #     if url_exists(new_url):
    #         return True, new_url

    return False, None


def urls_from_meta(meta_yaml) -> Set[str]:
    source = meta_yaml["source"]
    sources = []
    if not isinstance(source, List):
        sources = [source]
    else:
        sources = source
    urls = set()
    for s in sources:
        if "url" in s:
            # if it is a list for instance
            if not isinstance(s["url"], str):
                urls.update(s["url"])
            else:
                urls.add(s["url"])
    return urls


class BaseRawURL(AbstractSource):
    name = "BaseRawURL"
    next_ver_func = None

    def get_url(self, raw_yaml, context_dict, meta_yaml) -> Optional[str]:
        # this while statement runs until a bad version is found
        # then it uses the previous one
        orig_urls = urls_from_meta(meta_yaml)
        print("orig urls: %s", orig_urls)
        current_ver = meta_yaml["package"]["version"]
        current_sha256 = None
        orig_ver = current_ver
        found = True
        count = 0
        max_count = 10

        while found and count < max_count:
            found = False
            for next_ver in self.next_ver_func(current_ver):
                print("trying version: %s", next_ver)

                raw_yaml["context"]["version"] = next_ver
                context_dict["version"] = next_ver
                new_meta = get_rendered_yaml(raw_yaml, context_dict)

                new_urls = urls_from_meta(new_meta)
                if len(new_urls) == 0:
                    print("No URL in meta.yaml")
                    return None

                print("parsed new version: %s", new_meta["package"]["version"])
                url_to_use = None
                for url in new_urls:
                    # this URL looks bad if these things happen
                    if (
                        str(new_meta["package"]["version"]) != next_ver
                        or url in orig_urls
                    ):
                        print(
                            "skipping url '%s' due to "
                            "\n    %s = %s\n    %s = %s",
                            url,
                            'str(new_meta["package"]["version"]) != next_ver',
                            str(new_meta["package"]["version"]) != next_ver,
                            "url in orig_urls",
                            url in orig_urls,
                        )
                        continue

                    print("trying url: %s", url)
                    _exists, _url_to_use = url_exists_swap_exts(url)
                    if not _exists:
                        print(
                            "version %s does not exist for url %s",
                            next_ver,
                            url,
                        )
                        continue
                    else:
                        url_to_use = _url_to_use

                if url_to_use is not None:
                    found = True
                    count = count + 1
                    current_ver = next_ver
                    new_sha256 = get_sha256(url_to_use)
                    if new_sha256 is None or new_sha256 == current_sha256:
                        return None
                    current_sha256 = new_sha256
                    print("version %s is ok for url %s", current_ver, url_to_use)
                    break

        if count == max_count:
            return None
        if current_ver != orig_ver:
            print("using version %s", current_ver)
            return current_ver
        return None

    def get_version(self, url: str) -> str:
        return url


class RawURL(BaseRawURL):
    name = "RawURL"
    next_ver_func = functools.partial(next_version, increment_alpha=False)

class VersionFromFeed(AbstractSource):
    ver_prefix_remove = ["release-", "releases%2F", "v_", "v.", "v"]
    dev_vers = [
        "rc",
        "beta",
        "alpha",
        "dev",
        "a",
        "b",
        "init",
        "testing",
        "test",
        "pre",
    ]

    def get_version(self, url) -> Optional[str]:
        data = feedparser.parse(url)
        if data["bozo"] == 1:
            return None
        vers = []
        for entry in data["entries"]:
            ver = entry["link"].split("/")[-1]
            for prefix in self.ver_prefix_remove:
                if ver.startswith(prefix):
                    ver = ver[len(prefix) :]
            if any(s in ver.lower() for s in self.dev_vers):
                continue
            # Extract version number starting at the first digit.
            ver = re.search(r"(\d+[^\s]*)", ver).group(0)
            vers.append(ver)
        if vers:
            return max(vers, key=lambda x: VersionOrder(x.replace("-", ".")))
        else:
            return None

class Github(VersionFromFeed):
    name = "github"

    def get_url(self, meta_yaml) -> Optional[str]:
        if "github.com" not in meta_yaml["source"][0]["url"]:
            return None
        split_url = meta_yaml["source"][0]["url"].lower().split("/")
        package_owner = split_url[split_url.index("github.com") + 1]
        gh_package_name = split_url[split_url.index("github.com") + 2]
        return f"https://github.com/{package_owner}/{gh_package_name}/releases.atom"

def ensure_list(x):
    if not isinstance(x, list):
        return [x]
    else:
        return x

def _hash_url(url, hash_type, progress=False, conn=None, timeout=None):
    _hash = None
    try:
        ha = getattr(hashlib, hash_type)()

        timedout = False
        t0 = time.time()

        resp = requests.get(url, stream=True, timeout=timeout or 10)

        if timeout is not None:
            if time.time() - t0 > timeout:
                timedout = True

        if resp.status_code == 200 and not timedout:
            if "Content-length" in resp.headers:
                num = math.ceil(float(resp.headers["Content-length"]) / 8192)
            elif resp.url != url:
                # redirect for download
                h = requests.head(resp.url).headers
                if "Content-length" in h:
                    num = math.ceil(float(h["Content-length"]) / 8192)
                else:
                    num = None
            else:
                num = None

            loc = 0
            for itr, chunk in enumerate(resp.iter_content(chunk_size=8192)):
                ha.update(chunk)
                if num is not None and int((itr + 1) / num * 25) > loc and progress:
                    eta = (time.time() - t0) / (itr + 1) * (num - (itr + 1))
                    loc = int((itr + 1) / num * 25)
                    print(
                        "eta % 7.2fs: [%s%s]"
                        % (eta, "".join(["=" * loc]), "".join([" " * (25 - loc)])),
                    )
                if timeout is not None:
                    if time.time() - t0 > timeout:
                        timedout = True

            if not timedout:
                _hash = ha.hexdigest()
            else:
                _hash = None
        else:
            _hash = None
    except requests.ConnectionError:
        _hash = None
    except Exception as e:
        _hash = (repr(e),)
    finally:
        if conn is not None:
            conn.send(_hash)
            conn.close()
        else:
            return _hash


def hash_url(url, timeout=None, progress=False, hash_type="sha256"):
    """Hash a url with a timeout.

    Parameters
    ----------
    url : str
        The URL to hash.
    timeout : int, optional
        The timeout in seconds. If the operation goes longer than
        this amount, the hash will be returned as None. Set to `None`
        for no timeout.
    progress : bool, optional
        If True, show a simple progress meter.
    hash_type : str
        The kind of hash. Must be an attribute of `hashlib`.

    Returns
    -------
    hash : str or None
        The hash, possibly None if the operation timed out or the url does
        not exist.
    """
    _hash = None

    try:
        parent_conn, child_conn = Pipe()
        p = Process(
            target=_hash_url,
            args=(url, hash_type),
            kwargs={"progress": progress, "conn": child_conn},
        )
        p.start()
        if parent_conn.poll(timeout):
            _hash = parent_conn.recv()

        p.join(timeout=0)
        if p.exitcode != 0:
            p.terminate()
    except AssertionError as e:
        # if launched in a process we cannot use another process
        if "daemonic" in repr(e):
            _hash = _hash_url(
                url,
                hash_type,
                progress=progress,
                conn=None,
                timeout=timeout,
            )
        else:
            raise e

    if isinstance(_hash, tuple):
        raise eval(_hash[0])

    return _hash

def order_output_dict(d):
    result_list = []
    for k in RECIPE_FIELD_ORDER:
        if k in d:
            result_list.append((k, d[k]))

    leftover_keys = d.keys() - set(RECIPE_FIELD_ORDER)
    result_list += [(k, d[k]) for k in leftover_keys]
    return OrderedDict(result_list)

def get_yaml_loader(typ):
    if typ == "rt":
        loader = YAML(typ=typ)
        loader.preserve_quotes = True
        loader.default_flow_style = False
        loader.indent(sequence=4, offset=2)
        loader.width = 1000
        loader.Representer = MyRepresenter
        loader.Loader = ruamel.yaml.RoundTripLoader
    elif typ == "safe":
        loader = YAML(typ=typ)
    return loader

def render_recursive(dict_or_array, context_dict, jenv):
    # check if it's a dict?
    if isinstance(dict_or_array, collections.abc.Mapping):
        for key, value in dict_or_array.items():
            if isinstance(value, str):
                try:
                    tmpl = jenv.from_string(value)
                    dict_or_array[key] = tmpl.render(context_dict)
                except jinja2.exceptions.UndefinedError as e:
                    pass
            elif isinstance(value, collections.abc.Mapping):
                render_recursive(dict_or_array[key], context_dict, jenv)
            elif isinstance(value, collections.abc.Iterable):
                render_recursive(dict_or_array[key], context_dict, jenv)
    elif isinstance(dict_or_array, collections.abc.Iterable):
        for i in range(len(dict_or_array)):
            value = dict_or_array[i]
            if isinstance(value, str):
                try:
                    tmpl = jenv.from_string(value)
                    dict_or_array[i] = tmpl.render(context_dict)
                except jinja2.exceptions.UndefinedError as e:
                    pass
            elif isinstance(value, collections.abc.Mapping):
                render_recursive(value, context_dict, jenv)
            elif isinstance(value, collections.abc.Iterable):
                render_recursive(value, context_dict, jenv)

def normalize_recipe(ydoc):
    # normalizing recipe:
    # sources -> list
    # every output -> to outputs list
    if ydoc.get("context"):
        del ydoc["context"]

    if ydoc.get("source"):
        ydoc["source"] = ensure_list(ydoc["source"])

    if not ydoc.get("outputs"):
        ydoc["outputs"] = [{"package": ydoc["package"]}]

        toplevel_output = ydoc["outputs"][0]
    else:
        for o in ydoc["outputs"]:
            if o["package"]["name"] == ydoc["package"]["name"]:
                toplevel_output = o
                break
        else:
            # how do we handle no-output toplevel?!
            toplevel_output = None
            assert not ydoc.get("requirements")

    if ydoc.get("requirements"):
        # move these under toplevel output
        assert not toplevel_output.get("requirements")
        toplevel_output["requirements"] = ydoc["requirements"]
        del ydoc["requirements"]

    if ydoc.get("test"):
        # move these under toplevel output
        assert not toplevel_output.get("test")
        toplevel_output["test"] = ydoc["test"]
        del ydoc["test"]

    def move_to_toplevel(key):
        if ydoc.get("build", {}).get(key):
            if not toplevel_output.get("build"):
                toplevel_output["build"] = {}
            toplevel_output["build"][key] = ydoc["build"][key]
            del ydoc["build"][key]

    move_to_toplevel("run_exports")
    move_to_toplevel("ignore_run_exports")

    return ydoc

def get_raw_yaml(recipe_path):
    f = open(recipe_path, 'r')
    loader = get_yaml_loader(typ="rt")
    raw_yaml = loader.load(f)
    context_dict = raw_yaml.get("context") or {}
    return raw_yaml, context_dict

def get_rendered_yaml(raw_yaml, context_dict):
    rendered_yaml = copy.deepcopy(raw_yaml)
    jenv = jinja2.Environment()
    for key, value in context_dict.items():
        if isinstance(value, str):
            tmpl = jenv.from_string(value)
            context_dict[key] = tmpl.render(context_dict)

    for key in rendered_yaml:
        render_recursive(rendered_yaml[key], context_dict, jenv)

    rendered_yaml = normalize_recipe(rendered_yaml)
    return rendered_yaml

def is_new_version_available(raw_yaml, context_dict, rendered_yaml):
    raw_yaml = copy.deepcopy(raw_yaml)
    current_version = rendered_yaml["package"]["version"]
    github_url = Github().get_url(rendered_yaml)
    if github_url is not None:
        github_version = Github().get_version(github_url)
        if github_version is not None and VersionOrder(github_version) > VersionOrder(current_version):
            return True, github_version
    else:
        download_version = RawURL().get_url(raw_yaml, context_dict, rendered_yaml)
        if download_version is not None:
            if VersionOrder(download_version) > VersionOrder(current_version):
                return True, download_version
    return False, current_version

def get_new_url_for_new_version(raw_yaml, context_dict, new_version):
    yaml = copy.deepcopy(raw_yaml)
    context = copy.deepcopy(context_dict)
    yaml["context"]["version"] = new_version
    context["version"] = new_version
    rendered = get_rendered_yaml(yaml, context)
    return rendered["source"][0]["url"]

def get_sha256(url: str) -> Optional[str]:
    try:
        return hash_url(url, timeout=120, hash_type="sha256")
    except Exception as e:
        print("url hashing exception: %s", repr(e))
        return None

def get_updated_raw_yaml(recipe_path):
    raw_yaml, context_dict = get_raw_yaml(recipe_path)

    yaml    = copy.deepcopy(raw_yaml)
    context = copy.deepcopy(context_dict)
    rendered_yaml = get_rendered_yaml(yaml, context)
    package_name = rendered_yaml["package"]["name"]
    print(f"\nProcessing {package_name}")

    # Discarding python and python_abi
    if rendered_yaml['package']['name'] in ['python', 'python_abi', 'libpython']:
        return yaml ,False, rendered_yaml,None

    # TODO: Fix those recipes!
    # Discarding broken recipes
    if rendered_yaml['package']['name'] in ['sqlite', 'robotics-toolbox-python']:
        return yaml, False, rendered_yaml,None

    if "sha256" in context:
        sha256_hash_for_current = context["sha256"]
    else:
        if isinstance(rendered_yaml["source"], list):
            sha256_hash_for_current = rendered_yaml["source"][0]["sha256"]
        else:
            sha256_hash_for_current = rendered_yaml["source"]["sha256"]

    version_available, new_version = is_new_version_available(yaml, context, rendered_yaml)
    if not version_available:
        return raw_yaml, False,rendered_yaml,None

    url_for_version = get_new_url_for_new_version(yaml, context, new_version)
    sha256_hash_for_version = get_sha256(url_for_version)

    is_new = False
    if version_available and sha256_hash_for_version is not None and sha256_hash_for_version != sha256_hash_for_current:
        raw_yaml["context"]["version"] = new_version
        context["version"] = new_version
        if "sha256" in context:
            raw_yaml["context"]["sha256"] = sha256_hash_for_version
        else:
            if isinstance(raw_yaml["source"], list):
                raw_yaml["source"][0]["sha256"] = sha256_hash_for_version
            else:
                raw_yaml["source"]["sha256"] = sha256_hash_for_version
        raw_yaml["build"]["number"] = 0
        is_new = True
    return raw_yaml, is_new,rendered_yaml, new_version


#  gh pr create -B base_branch -H branch_to_merge --title 'Merge branch_to_merge into base_branch' --body 'Created by Github action'


@contextmanager
def updated_recipe_ctx(loader, recipe_info):
    recipe_path = recipe_info["path"]
    new_recipe = recipe_info["yaml"]
    
    # load the old recipe from disk
    old_recipe = loader.load(open(recipe_path, 'r'))

    # write new recipe
    with open(recipe_path, 'w') as f:
        loader.dump(order_output_dict(new_recipe), f)
    try:
        yield

    finally:
        # write old recipe
        with open(recipe_path, 'w') as f:
            loader.dump(order_output_dict(old_recipe), f)

def get_current_branch_name():
    return subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD']).decode('utf-8').strip()



@contextmanager
def git_branch_ctx(old_branch_name, new_branch_name):
    subprocess.check_output(['git', 'checkout', '-b', new_branch_name])


    try:
        yield
    finally:
        subprocess.check_output(['git', 'checkout', old_branch_name, "--force"])
        subprocess.check_output(['git', 'branch', '-D', new_branch_name])

if __name__ == "__main__":



    import glob
    loader = get_yaml_loader(typ="rt")
    recipes = glob.glob("recipes/recipes_emscripten/**/recipe.yaml")
    old_branch_name = get_current_branch_name()


    for each_recipe_path in recipes:
        updated_raw_yaml, is_updated, rendered_yaml, new_version = get_updated_raw_yaml(each_recipe_path)
        if is_updated:
            recipe_info = {
                "path": each_recipe_path,
                "yaml": updated_raw_yaml
            }

            name = rendered_yaml["package"]["name"]
            old_version = rendered_yaml["package"]["version"]

            branch_name = f"update_{name}_{old_version}_to_{new_version}"
            # replace all non-alphanumeric characters with _
            branch_name = re.sub(r'[^a-zA-Z0-9]', '_', branch_name)
            branch_name = branch_name.lower()

            pr_title = f"Update {name} from {old_version} to {new_version}"

            # check if there is already a PR with this title
            prs = subprocess.check_output(['gh', 'pr', 'list', '--search', pr_title]).decode('utf-8').strip()
            if prs:
                print(f"PR '{pr_title}' already exists")
                continue

            with git_branch_ctx(old_branch_name, branch_name):
                with updated_recipe_ctx(loader, recipe_info):
                    
                    print("branch_name", branch_name)

                    print("cwd", os.getcwd())

                    # git commit
                    subprocess.check_output(['git', 'add', recipe_info["path"]])
                    subprocess.check_output(['git', 'commit', '-m', pr_title])
                    subprocess.check_output(['git', 'push', '-u', 'origin', branch_name, "--force"])

                    # gh set default repo
                    subprocess.check_call(['gh', 'repo', 'set-default', 'emscripten-forge/recipes'], cwd=os.getcwd())
                    

                    # call gh to create a PR
                    subprocess.check_call(['gh', 'pr', 'create', '-B', 'main', '--title', pr_title, '--body', f'Created by Github action'], cwd=os.getcwd())


