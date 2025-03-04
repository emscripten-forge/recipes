

# add root to python path
import sys
sys.path.append('/')


# print all files/folders in /
import os
print("ROOT")
print(os.listdir('/'))

# print all files/folders in side-packages
print("SITE-PACKAGES")
print(os.listdir('/lib/python3.13/site-packages/'))

##########################################################################################
# The following tests were extracted from various tests files in the orignal repository

# test_array.py (partial)
import pyarrow as pa

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
import itertools
import pickle

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


def check_options_class(cls, **attr_values):
    """
    Check setting and getting attributes of an *Options class.
    """
    opts = cls()

    for name, values in attr_values.items():
        assert getattr(opts, name) == values[0], \
            "incorrect default value for " + name
        for v in values:
            setattr(opts, name, v)
            assert getattr(opts, name) == v, "failed setting value"

    with pytest.raises(AttributeError):
        opts.zzz_non_existent = True

    # Check constructor named arguments
    non_defaults = {name: values[1] for name, values in attr_values.items()}
    opts = cls(**non_defaults)
    for name, value in non_defaults.items():
        assert getattr(opts, name) == value


# The various options classes need to be picklable for dataset
def check_options_class_pickling(cls, **attr_values):
    opts = cls(**attr_values)
    new_opts = pickle.loads(pickle.dumps(opts,
                                         protocol=pickle.HIGHEST_PROTOCOL))
    for name, value in attr_values.items():
        assert getattr(new_opts, name) == value


class InvalidRowHandler:
    def __init__(self, result):
        self.result = result
        self.rows = []

    def __call__(self, row):
        self.rows.append(row)
        return self.result

    def __eq__(self, other):
        return (isinstance(other, InvalidRowHandler) and
                other.result == self.result)

    def __ne__(self, other):
        return (not isinstance(other, InvalidRowHandler) or
                other.result != self.result)


def test_read_options():
    cls = ReadOptions
    opts = cls()

    check_options_class(cls, use_threads=[True, False],
                        skip_rows=[0, 3],
                        column_names=[[], ["ab", "cd"]],
                        autogenerate_column_names=[False, True],
                        encoding=['utf8', 'utf16'],
                        skip_rows_after_names=[0, 27])

    check_options_class_pickling(cls, use_threads=True,
                                 skip_rows=3,
                                 column_names=["ab", "cd"],
                                 autogenerate_column_names=False,
                                 encoding='utf16',
                                 skip_rows_after_names=27)

    assert opts.block_size > 0
    opts.block_size = 12345
    assert opts.block_size == 12345

    opts = cls(block_size=1234)
    assert opts.block_size == 1234

    opts.validate()

    match = "ReadOptions: block_size must be at least 1: 0"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.block_size = 0
        opts.validate()

    match = "ReadOptions: skip_rows cannot be negative: -1"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.skip_rows = -1
        opts.validate()

    match = "ReadOptions: skip_rows_after_names cannot be negative: -1"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.skip_rows_after_names = -1
        opts.validate()

    match = "ReadOptions: autogenerate_column_names cannot be true when" \
            " column_names are provided"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.autogenerate_column_names = True
        opts.column_names = ('a', 'b')
        opts.validate()


def test_parse_options():
    cls = ParseOptions
    skip_handler = InvalidRowHandler('skip')

    check_options_class(cls, delimiter=[',', 'x'],
                        escape_char=[False, 'y'],
                        quote_char=['"', 'z', False],
                        double_quote=[True, False],
                        newlines_in_values=[False, True],
                        ignore_empty_lines=[True, False],
                        invalid_row_handler=[None, skip_handler])

    check_options_class_pickling(cls, delimiter='x',
                                 escape_char='y',
                                 quote_char=False,
                                 double_quote=False,
                                 newlines_in_values=True,
                                 ignore_empty_lines=False,
                                 invalid_row_handler=skip_handler)

    cls().validate()
    opts = cls()
    opts.delimiter = "\t"
    opts.validate()

    match = "ParseOptions: delimiter cannot be \\\\r or \\\\n"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.delimiter = "\n"
        opts.validate()

    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.delimiter = "\r"
        opts.validate()

    match = "ParseOptions: quote_char cannot be \\\\r or \\\\n"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.quote_char = "\n"
        opts.validate()

    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.quote_char = "\r"
        opts.validate()

    match = "ParseOptions: escape_char cannot be \\\\r or \\\\n"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.escape_char = "\n"
        opts.validate()

    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.escape_char = "\r"
        opts.validate()


def test_convert_options():
    cls = ConvertOptions
    opts = cls()

    check_options_class(
        cls, check_utf8=[True, False],
        strings_can_be_null=[False, True],
        quoted_strings_can_be_null=[True, False],
        decimal_point=['.', ','],
        include_columns=[[], ['def', 'abc']],
        include_missing_columns=[False, True],
        auto_dict_encode=[False, True],
        timestamp_parsers=[[], [ISO8601, '%y-%m']])

    check_options_class_pickling(
        cls, check_utf8=False,
        strings_can_be_null=True,
        quoted_strings_can_be_null=False,
        decimal_point=',',
        include_columns=['def', 'abc'],
        include_missing_columns=False,
        auto_dict_encode=True,
        timestamp_parsers=[ISO8601, '%y-%m'])

    with pytest.raises(ValueError):
        opts.decimal_point = '..'

    assert opts.auto_dict_max_cardinality > 0
    opts.auto_dict_max_cardinality = 99999
    assert opts.auto_dict_max_cardinality == 99999

    assert opts.column_types == {}
    # Pass column_types as mapping
    opts.column_types = {'b': pa.int16(), 'c': pa.float32()}
    assert opts.column_types == {'b': pa.int16(), 'c': pa.float32()}
    opts.column_types = {'v': 'int16', 'w': 'null'}
    assert opts.column_types == {'v': pa.int16(), 'w': pa.null()}
    # Pass column_types as schema
    schema = pa.schema([('a', pa.int32()), ('b', pa.string())])
    opts.column_types = schema
    assert opts.column_types == {'a': pa.int32(), 'b': pa.string()}
    # Pass column_types as sequence
    opts.column_types = [('x', pa.binary())]
    assert opts.column_types == {'x': pa.binary()}

    with pytest.raises(TypeError, match='DataType expected'):
        opts.column_types = {'a': None}
    with pytest.raises(TypeError):
        opts.column_types = 0

    assert isinstance(opts.null_values, list)
    assert '' in opts.null_values
    assert 'N/A' in opts.null_values
    opts.null_values = ['xxx', 'yyy']
    assert opts.null_values == ['xxx', 'yyy']

    assert isinstance(opts.true_values, list)
    opts.true_values = ['xxx', 'yyy']
    assert opts.true_values == ['xxx', 'yyy']

    assert isinstance(opts.false_values, list)
    opts.false_values = ['xxx', 'yyy']
    assert opts.false_values == ['xxx', 'yyy']

    assert opts.timestamp_parsers == []
    opts.timestamp_parsers = [ISO8601]
    assert opts.timestamp_parsers == [ISO8601]

    opts = cls(column_types={'a': pa.null()},
               null_values=['N', 'nn'], true_values=['T', 'tt'],
               false_values=['F', 'ff'], auto_dict_max_cardinality=999,
               timestamp_parsers=[ISO8601, '%Y-%m-%d'])
    assert opts.column_types == {'a': pa.null()}
    assert opts.null_values == ['N', 'nn']
    assert opts.false_values == ['F', 'ff']
    assert opts.true_values == ['T', 'tt']
    assert opts.auto_dict_max_cardinality == 999
    assert opts.timestamp_parsers == [ISO8601, '%Y-%m-%d']


def test_write_options():
    cls = WriteOptions
    opts = cls()

    check_options_class(
        cls, include_header=[True, False], delimiter=[',', '\t', '|'])

    assert opts.batch_size > 0
    opts.batch_size = 12345
    assert opts.batch_size == 12345

    opts = cls(batch_size=9876)
    assert opts.batch_size == 9876

    opts.validate()

    match = "WriteOptions: batch_size must be at least 1: 0"
    with pytest.raises(pa.ArrowInvalid, match=match):
        opts = cls()
        opts.batch_size = 0
        opts.validate()
