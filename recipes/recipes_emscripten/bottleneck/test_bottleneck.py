# Adapted from https://github.com/pydata/bottleneck/tree/4dab1d5753168e9ff9c8104603aca6e66cdb88c9/bottleneck/tests

# Copyright (c) 2010-2019 Keith Goodman
# Copyright (c) 2019 Bottleneck Developers
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.

#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


def test_move_median_without_nans():
    import bottleneck as bn
    import numpy as np
    from numpy.testing import assert_array_almost_equal

    min_count = 1
    size = 10
    func = bn.move_median
    func0 = bn.slow.move_median
    rs = np.random.RandomState([1, 2, 3])
    for _ in range(20):
        a = np.arange(size, dtype=np.int64)
        rs.shuffle(a)
        for window in range(2, size + 1):
            actual = func(a, window=window, min_count=min_count)
            desired = func0(a, window=window, min_count=min_count)
            assert_array_almost_equal(actual, desired, decimal=5)


def test_move_std_sqrt():
    import bottleneck as bn
    import numpy as np

    a = [
        0.0011448196318903589,
        0.00028718669878572767,
        0.00028718669878572767,
        0.00028718669878572767,
        0.00028718669878572767,
    ]
    b = bn.move_std(a, window=3)
    assert np.isfinite(b[2:]).all()

    a2 = np.array([a, a])
    b = bn.move_std(a2, window=3, axis=1)
    assert np.isfinite(b[:, 2:]).all()

    a3 = np.array([[a, a], [a, a]])
    b = bn.move_std(a3, window=3, axis=2)
    assert np.isfinite(b[:, :, 2:]).all()


def test_partition_transpose():
    import bottleneck as bn
    import numpy as np
    from numpy.testing import assert_equal

    a = np.arange(12).reshape(4, 3)
    actual = bn.partition(a.T, 2, -1).T
    desired = bn.slow.partition(a.T, 2, -1).T
    assert_equal(actual, desired)


def test_push():
    import bottleneck as bn
    import numpy as np
    from numpy.testing import assert_array_equal

    ns = (0, 1, 2, 3, 4, 5, None)
    a = np.array([np.nan, 1, 2, np.nan, np.nan, np.nan, np.nan, 3, np.nan])
    for n in ns:
        actual = bn.push(a.copy(), n=n)
        desired = bn.slow.push(a.copy(), n=n)
        assert_array_equal(actual, desired)
