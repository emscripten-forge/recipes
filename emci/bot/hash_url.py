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

from typing import Iterator
import requests
import hashlib
import math
import time
from multiprocessing import Process, Pipe



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

    if conn is None:
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