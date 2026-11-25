// Run by test_scilab.sh with scilab-cli.js (no JVM) under node.
// Each block goes through a different part of the build: LAPACK/BLAS and
// Scilab's Fortran (signature adapters, COMMON blocks), gateways of the
// modules that are normally loaded with dlopen (static symbol table), FFTW
// (looked up by name), callbacks from Fortran into Scilab, HDF5, matio, ...
mode(-1);
function ok(name)
    mprintf("ok: %s\n", name);
endfunction

// linear algebra
A = [4 1 2; 1 5 3; 2 3 6];
assert_checkalmostequal(det(A), 70, 1e-12);
x = A \ [1; 2; 3];
assert_checkalmostequal(A * x, [1; 2; 3], 1e-12);
[L, U, E] = lu(A);
assert_checkalmostequal(L * U, E * A, [], 1e-12);
assert_checkalmostequal(gsort(spec(A), "g", "i"), gsort(svd(A), "g", "i"), 1e-12);
[Q, R] = qr(A);
assert_checkalmostequal(Q * R, A, [], 1e-12);
assert_checkalmostequal(expm(zeros(2, 2)), eye(2, 2));
ok("linear algebra");

// polynomials, control (Fortran)
p = poly([1 2 3], "x");
assert_checkalmostequal(gsort(real(roots(p)), "g", "i"), [1; 2; 3], 1e-10);
s = poly(0, "s");
h = syslin("c", 1 / (s + 1));
assert_checkalmostequal(horner(h, 0), 1);
ok("polynomials");

// FFT (FFTW)
y = fft(ones(1, 8));
assert_checkalmostequal(y, [8 0 0 0 0 0 0 0], [], 1e-12);
assert_checkalmostequal(ifft(fft(1:16)), 1:16, 1e-12);
ok("fft");

// ODE and integration: Fortran solvers calling Scilab functions
function ydot = f(t, y)
    ydot = -y;
endfunction
yy = ode(1, 0, 1, f);
assert_checkalmostequal(yy, exp(-1), 1e-5);
assert_checkalmostequal(intg(0, %pi, sin), 2, 1e-8);
ok("ode, intg");

// optimization
function [f, g, ind] = cost(x, ind)
    f = sum((x - [1 2]).^2);
    g = 2 * (x - [1 2]);
endfunction
[fopt, xopt] = optim(cost, [0 0]);
assert_checkalmostequal(xopt, [1 2], 1e-6);
function y = fz(x)
    y = x.^2 - 2;
endfunction
assert_checkalmostequal(fsolve(1, fz), sqrt(2), 1e-8);
ok("optim, fsolve");

// calls through function pointers (types checked in WebAssembly):
// DCDFLIB through cdf_generic, odedc's example functions, Fortran I/O of
// arrays (descriptors: optim's verbose output), LAPACK's deprecated DGEQPF
[P, Q] = cdfnor("PQ", 1.96, 0, 1);
assert_checkalmostequal(P, 0.9750021, 1e-6);
[P, Q] = cdfbin("PQ", 5, 10, 0.5, 0.5);
assert_checkalmostequal(P, 0.623046875, 1e-9);
y = odedc(zeros(5, 1), 2, 0.1, 0, 0:0.1:2, "fcd");
assert_checkequal(size(y), [5 21]);
[fopt, xopt] = optim(cost, [0 0], imp=1);
assert_checkalmostequal(xopt, [1 2], 1e-6);
[Q, R, JPVT, rk] = rankqr([1 2; 2 4; 3 6], 1e-10);
assert_checkequal(rk, 1);
ok("calls through pointers, Fortran array I/O");

// Xcos simulation without windows: a diagram built here (clock, sine,
// scope: types 4, 0 and the "trash" that replaces the scope)
loadXcosLibs();
loadScicos();
scs_m = scicos_diagram();
scs_m.props.tf = 2;
scs_m.objs(1) = SampleCLK("define");
scs_m.objs(2) = GENSIN_f("define");
scs_m.objs(3) = CSCOPE("define");
scs_m.objs(4) = scicos_link(xx=[0; 0], yy=[0; 0], ct=[1 1], from=[2 1 0], to=[3 1 1]);
scs_m.objs(5) = scicos_link(xx=[0; 0], yy=[0; 0], ct=[5 -1], from=[1 1 0], to=[3 1 1]);
scs_m.objs(2).graphics.pout = 4;
scs_m.objs(3).graphics.pin = 4;
scs_m.objs(3).graphics.pein = 5;
scs_m.objs(1).graphics.peout = 5;
Info = scicos_simulate(scs_m, list(), "nw");
ok("xcos simulation");

// sparse matrices
S = sparse([1 1; 2 2; 3 3], [1 2 3]);
assert_checkalmostequal(full(S \ [1; 2; 3]), [1; 1; 1]);
ok("sparse");

// gateways of the dynamically loaded modules
grand("setsd", 0);
r = grand(1, 1000, "unf", 0, 1);
assert_checktrue(and(r >= 0 & r < 1));
assert_checkalmostequal(interp1([1 2 3], [10 20 30], 2.5), 25);
csvWrite([1 2; 3 4], TMPDIR + "/t.csv");
assert_checkequal(csvRead(TMPDIR + "/t.csv"), [1 2; 3 4]);
assert_checkalmostequal(filter(1, [1 -0.5], [1 0 0]), [1 0.5 0.25]);
ok("randlib, interpolation, spreadsheet, signal processing");

// strings, regular expressions (pcre2), JSON
assert_checkequal(regexp("abc123", "/[0-9]+/"), 4);
assert_checkequal(strsubst("hello world", "world", "wasm"), "hello wasm");
st = fromJSON("{""a"": [1, 2, 3]}");
assert_checkequal(st.a, [1 2 3]);
ok("strings, regexp, json");

// files: HDF5 (save/load), matio, xml
a = rand(3, 3);
b = a;
save(TMPDIR + "/t.sod", "a");
clear a;
load(TMPDIR + "/t.sod");
assert_checkequal(a, b);
savematfile(TMPDIR + "/t.mat", "b", "-v7");
clear b;
loadmatfile(TMPDIR + "/t.mat");
assert_checkequal(b, a);
doc = xmlReadStr("<a><b>1</b></a>");
assert_checkequal(doc.root.children(1).content, "1");
xmlDelete(doc);
ok("hdf5, matio, xml");

// errors are caught (C++ exceptions, longjmp)
assert_checkerror("error(""boom"")", "boom");
assert_checkequal(execstr("1 + []", "errcatch"), 0);
ok("errors");

mprintf("ALL TESTS PASSED\n");
