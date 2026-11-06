// Plain python tests, shared by the node test (node_test_wrapper.js) and the
// browser test (browser_test.html / browser_test.py).
// Each snippet runs in a fresh interpreter (run_python: Py_Initialize ..
// Py_FinalizeEx) and must not raise.

export const pythonTests = [
  {
    name: "platform",
    code: `
import sys, platform, sysconfig
assert sys.platform == "emscripten", sys.platform
assert sys.version_info[:2] == (3, 14), sys.version_info
assert sys.maxsize in (2**31 - 1, 2**63 - 1)
assert sysconfig.get_config_var("EXT_SUFFIX"), sysconfig.get_config_var("EXT_SUFFIX")
print(platform.platform())
`,
  },
  {
    name: "core language",
    code: `
import dataclasses, enum, typing
assert 2**200 // 3**50 == 2**200 // (3**50)
assert int("1" * 4000) % 9 == 4000 % 9           # long int <-> str (limit 4300 digits)
assert repr(0.1 + 0.2) == "0.30000000000000004"
assert f"{3.14159:.2f}|{255:#x}|{'é':>3}" == "3.14|0xff|  é"
assert "ünïcödé".encode("utf-8").decode("utf-8") == "ünïcödé"
assert [x * x for x in range(5) if x % 2] == [1, 9]
def gen():
    yield from range(3)
assert list(gen()) == [0, 1, 2]
@dataclasses.dataclass(frozen=True)
class P:
    x: int
    y: int = 0
assert P(1) == P(1, 0)
class Color(enum.Enum):
    RED = 1
assert Color(1) is Color.RED
match {"k": [1, 2]}:
    case {"k": [a, b]}:
        assert (a, b) == (1, 2)
T = typing.TypeVar("T")
try:
    raise ExceptionGroup("g", [ValueError(1), KeyError(2)])
except* ValueError as eg:
    assert len(eg.exceptions) == 1
except* KeyError:
    pass
`,
  },
  {
    name: "exceptions and tracebacks",
    code: `
import traceback
def f():
    raise ValueError("boom")
try:
    f()
except ValueError as e:
    text = "".join(traceback.format_exception(e))
    assert "boom" in text and "in f" in text, text
`,
  },
  {
    name: "recursion limit",
    code: `
import sys
def depth(n):
    return 0 if n == 0 else 1 + depth(n - 1)
assert depth(800) == 800
def forever(n):
    return forever(n + 1)
try:
    forever(0)
except RecursionError:
    pass
else:
    raise AssertionError("expected RecursionError")
`,
  },
  {
    name: "stdlib (pure python)",
    code: `
import json, re, collections, itertools, functools, heapq, bisect, copy, pickle
import base64, binascii, struct, array, textwrap, string, csv, io, fractions, statistics
assert json.loads(json.dumps({"a": [1, 2.5, None, True]})) == {"a": [1, 2.5, None, True]}
assert re.findall(r"(\\w+)@(\\w+)", "a@b c@d") == [("a", "b"), ("c", "d")]
assert collections.Counter("abca").most_common(1) == [("a", 2)]
assert list(itertools.accumulate([1, 2, 3])) == [1, 3, 6]
assert functools.reduce(lambda a, b: a * b, range(1, 6)) == 120
assert heapq.nsmallest(2, [5, 1, 3]) == [1, 3]
assert bisect.bisect([1, 3, 5], 4) == 2
assert pickle.loads(pickle.dumps({1: (2, [3])})) == {1: (2, [3])}
assert base64.b64decode(base64.b64encode(b"\\x00\\xff")) == b"\\x00\\xff"
assert binascii.crc32(b"abc") == 891568578
assert struct.unpack("<iQd", struct.pack("<iQd", -1, 2**60, 0.5)) == (-1, 2**60, 0.5)
assert array.array("i", [1, 2]).tobytes() == struct.pack("=ii", 1, 2)
assert list(csv.reader(io.StringIO('a,"b,c"\\n'))) == [["a", "b,c"]]
assert fractions.Fraction(1, 3) + fractions.Fraction(1, 6) == fractions.Fraction(1, 2)
assert statistics.median([3, 1, 2]) == 2
`,
  },
  {
    name: "math / random / time / datetime",
    code: `
import math, cmath, random, time, datetime
assert math.isclose(math.sin(math.pi / 2), 1.0)
assert cmath.sqrt(-1) == 1j
assert math.factorial(20) == 2432902008176640000
r = random.Random(42)
assert [r.randint(0, 100) for _ in range(3)] == [81, 14, 3]
t0 = time.time(); assert t0 > 1.6e9
assert time.monotonic() <= time.monotonic()
d = datetime.datetime(2024, 2, 29, 12, 0) + datetime.timedelta(days=1)
assert d.isoformat() == "2024-03-01T12:00:00"
assert datetime.datetime.fromisoformat("2024-01-01T00:00:00+02:00").utcoffset().seconds == 7200
`,
  },
  {
    name: "decimal (libmpdec)",
    code: `
import decimal
decimal.getcontext().prec = 50
assert str(decimal.Decimal(1) / decimal.Decimal(7))[:12] == "0.1428571428"
assert decimal.Decimal("1.10") + decimal.Decimal("2.20") == decimal.Decimal("3.30")
import _decimal  # the C implementation, not _pydecimal
`,
  },
  {
    name: "unicodedata",
    code: `
import unicodedata
assert unicodedata.name("é") == "LATIN SMALL LETTER E WITH ACUTE"
assert unicodedata.normalize("NFD", "é") == "e\\u0301"
`,
  },
  {
    name: "compression (zlib / bz2 / lzma / zstd)",
    code: `
import zlib, bz2, lzma, gzip, zipfile, tarfile, io
data = b"pyjs " * 1000
assert zlib.decompress(zlib.compress(data)) == data
assert bz2.decompress(bz2.compress(data)) == data
assert lzma.decompress(lzma.compress(data)) == data
assert gzip.decompress(gzip.compress(data)) == data
from compression import zstd
assert zstd.decompress(zstd.compress(data)) == data
buf = io.BytesIO()
with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("a.txt", data)
with zipfile.ZipFile(buf) as z:
    assert z.read("a.txt") == data
buf = io.BytesIO()
with tarfile.open(fileobj=buf, mode="w:xz") as t:
    info = tarfile.TarInfo("a.txt"); info.size = len(data)
    t.addfile(info, io.BytesIO(data))
buf.seek(0)
with tarfile.open(fileobj=buf, mode="r:xz") as t:
    assert t.extractfile("a.txt").read() == data
`,
  },
  {
    name: "hashlib / hmac / secrets (HACL*, openssl)",
    code: `
import hashlib, hmac, secrets
assert hashlib.md5(b"abc").hexdigest() == "900150983cd24fb0d6963f7d28e17f72"
assert hashlib.sha1(b"abc").hexdigest() == "a9993e364706816aba3e25717850c26c9cd0d89d"
assert hashlib.sha256(b"abc").hexdigest() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
assert hashlib.sha3_256(b"abc").hexdigest() == "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"
assert hashlib.blake2b(b"abc", digest_size=8).hexdigest() == "d8bb14d833d59559"
assert hmac.new(b"k", b"m", "sha256").hexdigest() == hmac.new(b"k", b"m", hashlib.sha256).hexdigest()
assert len(secrets.token_bytes(16)) == 16
`,
  },
  {
    name: "ssl",
    code: `
import ssl
assert ssl.OPENSSL_VERSION.startswith("OpenSSL"), ssl.OPENSSL_VERSION
ctx = ssl.create_default_context()
assert ctx.verify_mode == ssl.CERT_REQUIRED
`,
  },
  {
    name: "xml (expat)",
    code: `
import xml.etree.ElementTree as ET, xml.dom.minidom, pyexpat
root = ET.fromstring("<a><b x='1'>t</b></a>")
assert root.find("b").get("x") == "1" and root.find("b").text == "t"
assert xml.dom.minidom.parseString("<a/>").documentElement.tagName == "a"
`,
  },
  {
    name: "sqlite3",
    code: `
import sqlite3
con = sqlite3.connect(":memory:")
con.execute("create table t (a integer, b text)")
con.executemany("insert into t values (?, ?)", [(1, "x"), (2, "y")])
assert con.execute("select sum(a), group_concat(b) from t").fetchone() == (3, "x,y")
assert sqlite3.sqlite_version_info >= (3, 0, 0)
`,
  },
  {
    name: "ctypes (libffi)",
    code: `
import ctypes, sys
assert ctypes.sizeof(ctypes.c_void_p) * 8 == (64 if sys.maxsize > 2**32 else 32)
buf = ctypes.create_string_buffer(b"hello")
assert buf.value == b"hello"
class S(ctypes.Structure):
    _fields_ = [("a", ctypes.c_int), ("b", ctypes.c_double)]
s = S(1, 2.5)
assert (s.a, s.b) == (1, 2.5)
arr = (ctypes.c_int * 3)(1, 2, 3)
assert list(arr) == [1, 2, 3]
`,
  },
  {
    name: "filesystem / os",
    code: `
import os, pathlib, tempfile, shutil, glob
d = tempfile.mkdtemp()
p = pathlib.Path(d) / "sub" / "f.txt"
p.parent.mkdir(parents=True)
p.write_text("hello")
assert p.read_text() == "hello"
assert glob.glob(os.path.join(d, "*", "*.txt")) == [str(p)]
shutil.copy(p, p.with_suffix(".bak"))
assert sorted(os.listdir(p.parent)) == ["f.bak", "f.txt"]
shutil.rmtree(d)
assert not os.path.exists(d)
os.environ["PY_TEST_VAR"] = "1"
assert os.environ["PY_TEST_VAR"] == "1"
`,
  },
  {
    name: "gc / weakref / threading module",
    code: `
import gc, weakref, threading
class A: pass
a = A(); r = weakref.ref(a)
del a; gc.collect()
assert r() is None
assert threading.current_thread() is threading.main_thread()
lock = threading.Lock()
with lock:
    pass
`,
  },
  {
    // asyncio.run needs socket.socketpair() (selector event loop), which is not
    // available on emscripten (pyjs ships its own event loop): drive the
    // coroutines with a minimal round-robin scheduler instead
    name: "coroutines",
    code: `
import types, collections
@types.coroutine
def switch():
    yield
async def worker(name, n, log):
    for i in range(n):
        log.append(name)
        await switch()
    return name
def run_all(*coros):
    ready, results = collections.deque(coros), {}
    while ready:
        coro = ready.popleft()
        try:
            coro.send(None)
            ready.append(coro)
        except StopIteration as stop:
            results[stop.value] = True
    return results
log = []
results = run_all(worker("a", 3, log), worker("b", 3, log))
assert sorted(results) == ["a", "b"], results
assert log == ["a", "b"] * 3, log
import asyncio  # importable, even though asyncio.run is not usable here
`,
  },
];
