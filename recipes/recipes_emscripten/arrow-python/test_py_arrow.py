import pyarrow as pa

##########################################################################################
# The following tests were extracted from various tests files in the orignal repository

# test_array.py (partial)


import weakref
import pytest

def test_total_bytes_allocated():
    assert pa.total_allocated_bytes() == 0


def test_weakref():
    arr = pa.array([1, 2, 3])
    wr = weakref.ref(arr)
    assert wr() is not None
    del arr
    assert wr() is None


def test_getitem_NULL():
    arr = pa.array([1, None, 2])
    assert arr[1].as_py() is None
    assert arr[1].is_valid is False
    assert isinstance(arr[1], pa.Int64Scalar)


def test_constructor_raises():
    # This could happen by wrong capitalization.
    # ARROW-2638: prevent calling extension class constructors directly
    with pytest.raises(TypeError):
        pa.Array([1, 2])


def test_list_format():
    arr = pa.array([[1], None, [2, 3, None]])
    result = arr.to_string()
    expected = """\
[
  [
    1
  ],
  null,
  [
    2,
    3,
    null
  ]
]"""
    assert result == expected


def test_string_format():
    arr = pa.array(['', None, 'foo'])
    result = arr.to_string()
    expected = """\
[
  "",
  null,
  "foo"
]"""
    assert result == expected


def test_long_array_format():
    arr = pa.array(range(100))
    result = arr.to_string(window=2)
    expected = """\
[
  0,
  1,
  ...
  98,
  99
]"""
    assert result == expected


def test_indented_string_format():
    arr = pa.array(['', None, 'foo'])
    result = arr.to_string(indent=1)
    expected = '[\n "",\n null,\n "foo"\n]'

    assert result == expected


def test_top_level_indented_string_format():
    arr = pa.array(['', None, 'foo'])
    result = arr.to_string(top_level_indent=1)
    expected = ' [\n   "",\n   null,\n   "foo"\n ]'

    assert result == expected


def test_binary_format():
    arr = pa.array([b'\x00', b'', None, b'\x01foo', b'\x80\xff'])
    result = arr.to_string()
    expected = """\
[
  00,
  ,
  null,
  01666F6F,
  80FF
]"""
    assert result == expected

#### test_csv.py (partial)
import numpy as np
import string
import io

from pyarrow.csv import (
    open_csv, read_csv, ReadOptions, ParseOptions, ConvertOptions, ISO8601,
    write_csv, WriteOptions, CSVWriter, InvalidRow)



def generate_col_names():
    # 'a', 'b'... 'z', then 'aa', 'ab'...
    letters = string.ascii_lowercase
    yield from letters
    for first in letters:
        for second in letters:
            yield first + second


def make_random_csv(num_cols=2, num_rows=10, linesep='\r\n', write_names=True):
    arr = np.random.RandomState(42).randint(0, 1000, size=(num_cols, num_rows))
    csv = io.StringIO()
    col_names = list(itertools.islice(generate_col_names(), num_cols))
    if write_names:
        csv.write(",".join(col_names))
        csv.write(linesep)
    for row in arr.T:
        csv.write(",".join(map(str, row)))
        csv.write(linesep)
    csv = csv.getvalue().encode()
    columns = [pa.array(a, type=pa.int64()) for a in arr]
    expected = pa.Table.from_arrays(columns, col_names)
    return csv, expected


def make_empty_csv(column_names):
    csv = io.StringIO()
    csv.write(",".join(column_names))
    csv.write("\n")
    return csv.getvalue().encode()

