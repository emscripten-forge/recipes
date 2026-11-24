"""psutil for Emscripten / WebAssembly: a pure-python stand-in.

The real psutil reads /proc, sysctl & co. None of that exists in a browser: there is
exactly one process (us), threads are not allowed, and the "machine" is the wasm memory
of this tab. This module offers psutil's API and answers with the best values possible
in that world, so that libraries which import psutil (to log memory, size a pool, pick
CPUs, ...) keep working:

- cpu_count() is always 1: there is no threading, so nobody must size a thread or
  process pool above 1
- memory: total = how far the wasm heap may grow, used = how far it has grown
- the process list holds only this process
- disks, network, sensors, users: empty or zeros
- anything else psutil has but this module doesn't raises AccessDenied (callers of
  psutil handle that already)
"""

import collections
import contextlib
import os
import sys
import time

__version__ = "7.2.2"
version_info = tuple(int(x) for x in __version__.split("."))

# the platform constants: none of the real ones (it is not Linux, macOS, ...)
POSIX = True
WINDOWS = LINUX = MACOS = OSX = FREEBSD = OPENBSD = NETBSD = BSD = SUNOS = AIX = False
EMSCRIPTEN = True

STATUS_RUNNING = "running"
STATUS_SLEEPING = "sleeping"
STATUS_ZOMBIE = "zombie"
STATUS_DEAD = "dead"

CONN_NONE = "NONE"
NIC_DUPLEX_UNKNOWN = 0

_START = time.time()  # the "process" started when python imported this module
_WASM64 = sys.maxsize > 2**32


# ---- exceptions (as psutil's) ----

class Error(Exception):
    """the base of all psutil exceptions"""


class NoSuchProcess(Error):
    def __init__(self, pid=None, name=None, msg=None):
        self.pid, self.name = pid, name
        super().__init__(msg or f"process no longer exists (pid={pid})")


class ZombieProcess(NoSuchProcess):
    pass


class AccessDenied(Error):
    def __init__(self, pid=None, name=None, msg=None):
        self.pid, self.name = pid, name
        super().__init__(msg or "not available in WebAssembly")


class TimeoutExpired(Error):
    def __init__(self, seconds, pid=None, name=None):
        self.seconds, self.pid, self.name = seconds, pid, name
        super().__init__(f"timeout after {seconds} seconds")


def _not_available(name):
    def function(*args, **kwargs):
        raise AccessDenied(msg=f"psutil.{name} is not available in WebAssembly")
    function.__name__ = name
    return function


# ---- result types (the field names of psutil's) ----

svmem = collections.namedtuple("svmem", "total available percent used free")
sswap = collections.namedtuple("sswap", "total used free percent sin sout")
scputimes = collections.namedtuple("scputimes", "user system idle")
scpustats = collections.namedtuple("scpustats", "ctx_switches interrupts soft_interrupts syscalls")
sdiskusage = collections.namedtuple("sdiskusage", "total used free percent")
sdiskio = collections.namedtuple("sdiskio", "read_count write_count read_bytes write_bytes read_time write_time")
snetio = collections.namedtuple("snetio", "bytes_sent bytes_recv packets_sent packets_recv errin errout dropin dropout")
pmem = collections.namedtuple("pmem", "rss vms")
pfullmem = collections.namedtuple("pfullmem", "rss vms uss")
pcputimes = collections.namedtuple("pcputimes", "user system children_user children_system")
pthread = collections.namedtuple("pthread", "id user_time system_time")
pio = collections.namedtuple("pio", "read_count write_count read_bytes write_bytes")
pctxsw = collections.namedtuple("pctxsw", "voluntary involuntary")
puids = collections.namedtuple("puids", "real effective saved")
pgids = collections.namedtuple("pgids", "real effective saved")


# ---- memory: the wasm heap ----

def _heap():
    """(size, max): how big the wasm heap is now and how big it may grow, in bytes"""
    try:  # emscripten's own numbers (libc of the main module)
        import ctypes

        libc = ctypes.CDLL(None)
        for name in ("emscripten_get_heap_size", "emscripten_get_heap_max"):
            getattr(libc, name).restype = ctypes.c_size_t
        return int(libc.emscripten_get_heap_size()), int(libc.emscripten_get_heap_max())
    except Exception:
        pass
    # unknown: python's own peak, and the address space of the architecture
    size = 0
    try:
        import resource

        size = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    except Exception:
        pass
    return size, (16 if _WASM64 else 4) * 1024**3


def _device_memory():
    """the browser's guess of the device's memory in bytes (Chrome: navigator.deviceMemory,
    in GiB, rounded), or None"""
    try:
        import pyjs

        value = float(pyjs.js.navigator.deviceMemory)
        return int(value * 1024**3) if value > 0 else None
    except Exception:
        return None


def virtual_memory():
    size, limit = _heap()
    device = _device_memory()
    total = min(limit, device) if device else limit
    total = max(total, size)
    available = total - size
    return svmem(total, available, round(100.0 * size / total, 1) if total else 0.0, size, available)


def swap_memory():
    return sswap(0, 0, 0, 0.0, 0, 0)


# ---- cpu: one, never busy as far as we know ----

def cpu_count(logical=True):
    return 1  # no threading in the browser: pools must not grow beyond 1


def _cpu_times():
    t = os.times()
    return scputimes(t.user, t.system, max(0.0, time.time() - _START - t.user - t.system))


def cpu_times(percpu=False):
    return [_cpu_times()] if percpu else _cpu_times()


def cpu_percent(interval=None, percpu=False):
    if interval:
        time.sleep(interval)
    return [0.0] if percpu else 0.0


def cpu_times_percent(interval=None, percpu=False):
    if interval:
        time.sleep(interval)
    t = scputimes(0.0, 0.0, 100.0)
    return [t] if percpu else t


def cpu_stats():
    return scpustats(0, 0, 0, 0)


def cpu_freq(percpu=False):
    return [] if percpu else None


def getloadavg():
    return (0.0, 0.0, 0.0)


# ---- the system ----

def boot_time():
    return 0.0


def users():
    return []


def disk_usage(path):
    st = os.statvfs(path)
    total = st.f_blocks * st.f_frsize
    free = st.f_bavail * st.f_frsize
    used = total - st.f_bfree * st.f_frsize
    return sdiskusage(total, used, free, round(100.0 * used / total, 1) if total else 0.0)


def disk_partitions(all=False):
    return []


def disk_io_counters(perdisk=False, nowrap=True):
    return {} if perdisk else sdiskio(0, 0, 0, 0, 0, 0)


def net_io_counters(pernic=False, nowrap=True):
    return {} if pernic else snetio(0, 0, 0, 0, 0, 0, 0, 0)


def net_connections(kind="inet"):
    return []


def net_if_addrs():
    return {}


def net_if_stats():
    return {}


def sensors_temperatures(fahrenheit=False):
    return {}


def sensors_fans():
    return {}


def sensors_battery():
    return None


# ---- processes: only this one ----

class Process:
    """this process (the only one there is)"""

    def __init__(self, pid=None):
        if pid is not None and pid != os.getpid():
            raise NoSuchProcess(pid)
        self._pid = os.getpid()
        self.info = {}  # (filled by process_iter(attrs))

    pid = property(lambda self: self._pid)

    def __repr__(self):
        return f"psutil.Process(pid={self._pid}, name='python', status='running')"

    def __eq__(self, other):
        return isinstance(other, Process) and other.pid == self.pid

    def __hash__(self):
        return hash(self._pid)

    @contextlib.contextmanager
    def oneshot(self):
        yield

    def as_dict(self, attrs=None, ad_value=None):
        names = attrs or ["pid", "ppid", "name", "exe", "cmdline", "status", "username",
                          "create_time", "cwd", "num_threads", "cpu_times", "memory_info",
                          "memory_percent", "cpu_percent", "nice", "environ"]
        result = {}
        for name in names:
            try:
                value = getattr(self, name)
                result[name] = value() if callable(value) else value
            except Error:
                result[name] = ad_value
        return result

    # who
    def ppid(self):
        return 0

    def parent(self):
        return None

    def parents(self):
        return []

    def children(self, recursive=False):
        return []

    def name(self):
        return "python"

    def exe(self):
        return sys.executable or ""

    def cmdline(self):
        return list(sys.argv)

    def environ(self):
        return dict(os.environ)

    def cwd(self):
        return os.getcwd()

    def username(self):
        return "web_user"

    def uids(self):
        return puids(0, 0, 0)

    def gids(self):
        return pgids(0, 0, 0)

    def terminal(self):
        return None

    def create_time(self):
        return _START

    def status(self):
        return STATUS_RUNNING

    def is_running(self):
        return True

    # cpu
    def cpu_times(self):
        t = os.times()
        return pcputimes(t.user, t.system, 0.0, 0.0)

    def cpu_percent(self, interval=None):
        if interval:
            time.sleep(interval)
        return 0.0

    def cpu_affinity(self, cpus=None):
        return [0] if cpus is None else None  # (setting it: nothing to do)

    def cpu_num(self):
        return 0

    def nice(self, value=None):
        return 0 if value is None else None

    def num_threads(self):
        return 1

    def threads(self):
        t = os.times()
        return [pthread(self._pid, t.user, t.system)]

    def num_ctx_switches(self):
        return pctxsw(0, 0)

    # memory
    def memory_info(self):
        size, _ = _heap()
        return pmem(size, size)

    def memory_full_info(self):
        size, _ = _heap()
        return pfullmem(size, size, size)

    def memory_percent(self, memtype="rss"):
        return virtual_memory().percent

    def memory_maps(self, grouped=True):
        return []

    # files and network
    def open_files(self):
        return []

    def num_fds(self):
        return 0

    def net_connections(self, kind="inet"):
        return []

    connections = net_connections

    def io_counters(self):
        return pio(0, 0, 0, 0)

    # signals: nothing may stop us from here
    def send_signal(self, sig=None):
        raise AccessDenied(self._pid)

    suspend = resume = terminate = kill = send_signal

    def wait(self, timeout=None):
        raise TimeoutExpired(timeout, self._pid)

    def __getattr__(self, name):  # (what psutil has and this doesn't)
        if name.startswith("_"):
            raise AttributeError(name)
        return _not_available(f"Process.{name}")


Popen = _not_available("Popen")  # (no subprocesses in the browser)


def pids():
    return [os.getpid()]


def pid_exists(pid):
    return pid == os.getpid()


def process_iter(attrs=None, ad_value=None):
    process = Process()
    if attrs is not None:
        process.info = process.as_dict(attrs, ad_value)
    yield process


def wait_procs(procs, timeout=None, callback=None):
    return [], list(procs)


def test():
    """psutil.test(): a ps-like listing"""
    p = Process()
    print(f"USER      PID  %MEM   RSS  NAME\n{p.username():8} {p.pid:4} {p.memory_percent():5.1f} "
          f"{p.memory_info().rss // 1024**2:4}M  {p.name()}")


def __getattr__(name):  # (module level: what psutil has and this doesn't)
    if name.startswith("_"):
        raise AttributeError(name)
    return _not_available(name)
