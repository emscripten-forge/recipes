"""
Staged so that the log says which step fails.

The whole wasm runtime dies on a stack overflow somewhere in here, and a
test that imports, constructs and computes in one function cannot say
which of those did it. Each stage prints before it acts, so the last line
printed identifies the culprit even when the process does not survive to
report a result.
"""


def _log(msg):
    print("CYPARI2-PROBE: " + msg, flush=True)


def test_1_import():
    # Imports cypari2, which imports cysignals, which calls init_cysignals()
    # -- signal handlers and sigsetjmp machinery, the parts of this stack
    # least likely to be sound under Emscripten.
    _log("importing cypari2")
    import cypari2
    _log("imported cypari2 " + cypari2.__version__)


def test_2_construct():
    # Pari() calls pari_init_opts(), which allocates PARI's own stack and
    # sets up its error recovery with setjmp. Emscripten only supports
    # setjmp/longjmp when built for it, and a longjmp that lands wrongly
    # would look exactly like the runaway recursion in the log.
    from cypari2 import Pari
    _log("constructing Pari()")
    pari = Pari()
    _log("constructed Pari()")


def test_3_smallest_computation():
    from cypari2 import Pari
    pari = Pari()
    _log("evaluating 2+2")
    result = str(pari('2+2'))
    _log("2+2 = " + result)
    assert result == '4'


def test_4_bigger_integers():
    from cypari2 import Pari
    pari = Pari()
    _log("evaluating 2^64 (exercises GMP)")
    assert str(pari('2^64')) == '18446744073709551616'
    _log("2^64 ok")


def test_5_number_field():
    # What SnapPy actually needs PARI for.
    from cypari2 import Pari
    pari = Pari()
    _log("evaluating nfdisc(x^3-2)")
    assert str(pari('nfdisc(x^3-2)')) == '-108'
    _log("nfdisc ok")
