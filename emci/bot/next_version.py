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
from typing import List

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