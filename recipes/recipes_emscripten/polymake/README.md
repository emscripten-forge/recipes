# polymake for emscripten-wasm32

polymake is a perl application with a very large C++ core. This recipe departs
from upstream's build model in one significant way, and everything else follows
from it, so it is worth writing down.

## What has been verified to run

Built here against emscripten 4.0.9 (clang 21) and run under node:

```
polymake version 4.15

cube(3) vertices     : 8          cube(4) f-vector     : 16 32 24 8
cube(3) volume       : 8          convex hull facets   : 4   (uses ppl)
simplex(3) lattice pts: 4         Hilbert basis        : 4   (uses libnormaliz)
graph isomorphism    : true (uses bliss)
polytope from inequalities, exact rational volume 1/2, cyclic(4,8),
topaz::SimplicialComplex, matroid::Matroid -- all correct.
```

The binary is 57MB of wasm plus a 49MB filesystem image.

## Why this is not a straightforward port

Natively, polymake runs as `perl bin/polymake`. The perl interpreter loads
`Polymake::Ext` through `DynaLoader`, and then `Polymake::Core::CPlusPlus`
loads one shared module per application (`common.so`, `polytope.so`,
`topaz.so`, …) with `DynaLoader::dl_load_file`.

The emscripten-forge `perl` package is a static interpreter:

```
usedl='undef'   dlsrc='dl_none.xs'   dlext='none'   useshrplib='false'
```

`dl_none.xs` is the stub implementation — `dl_load_file` cannot succeed, ever.
So the upstream runtime model does not survive the port, and neither does the
`libpolymake.so` + `libperl.so` arrangement the callable library normally uses.

## What this recipe builds instead

polymake's *callable* interface already contains most of what a static build
needs. `pm::perl::Main` constructs the perl interpreter from C++ and passes
`xs_init` from the generated `polymakeBootstrapXS.h`, which registers every core
XS module statically — `createBootstrap.pl` exists precisely for that. On top of
that, application clients register themselves from C++ static constructors, not
through XS boot functions, so linking an application in is enough to make it
available; nothing needs to be looked up by symbol name at runtime.

The build therefore:

1. archives every "shared module" instead of linking it (patch 0002), so the
   per-application modules, `Polymake::Ext` and the callable library all come out
   as `ar` archives;
2. links the application archives, the callable archive, `libperl.a` and a small
   driver into one wasm executable, with `--whole-archive` — **not** an
   optimization choice: an archive member that resolves no undefined symbol would
   otherwise be dropped and its static constructors, and hence its registrations,
   lost;
3. holds every client registration back until the perl side is ready
   (patch 0015). This is the one place where linking the applications in is not
   simply "the same thing, earlier": the registrators run from static
   constructors, and when the applications are shared modules those constructors
   run at `dlopen`, long after the interpreter exists. Fused into one executable
   they all run before `main()`, and the first one reaches
   `RegistratorQueue::RegistratorQueue`, which dereferences a
   `Polymake::Core::CPlusPlus::root` that has not been created yet:

   ```
   RuntimeError: memory access out of bounds
       at pm::perl::RegistratorQueue::RegistratorQueue(polymake::AnyString const&, ...)
       at _GLOBAL__sub_I_wrap_bounding_box.cc
       at __wasm_call_ctors
   ```

   So `QueueingRegistrator4perl` and `StaticRegistrator4perl` now hand the work
   to `pm::perl::defer_registration()` instead of doing it. Until
   `Polymake::Core::CPlusPlus::init()` calls `run_deferred_registrations()` the
   callbacks are queued; from then on they run as they arrive, so a module
   loaded later behaves exactly as before and the standard dynamic build is
   unaffected apart from the order of the first batch. The queue is kept rather
   than freed afterwards, because the argument copies the callbacks hold are what
   the `AnyString`s handed to perl point at;
4. registers perl's own static extensions from `xs_init` (patch 0007). A perl
   with `usedl='undef'` keeps POSIX, Storable, List::Util, IO, Encode and the
   rest as separate archives under `archlib/auto/` — they are *not* in
   `libperl.a` — and nothing loads them at runtime, so their boot functions have
   to be registered the same way perl's own `perlmain.c` does for a static perl.
   Without this the interpreter starts and then dies on the first `use POSIX`.
   `build.sh` derives the list from the archives actually present rather than
   from `$Config{static_ext}`, because the two disagree (`Devel::PPPort` is
   listed but installs no archive);
5. packs the rule files, application perl code and the perl library tree into
   `polymake.data` with `file_packager.py`;
6. keeps `libpolymake.a`, `libpolymake-core.a` and the headers so other
   emscripten-forge packages can embed polymake themselves.

`polymake_wasm_main.cc` is the driver. It passes both installation directories to
`pm::perl::Main` explicitly (patch 0005 removes the `dladdr`/`dlopen` based
deduction, which cannot work without shared objects) and drives
`Main::shell_execute`, so the same binary serves a stdin REPL, `-e CODE`,
`--script FILE`, and direct calls from JavaScript through the exported
`polymake_*` functions.

## Cross-compilation

polymake's `configure` learns everything about perl from the interpreter running
it, which makes a cross build awkward: the target perl is a wasm binary and
cannot run on the build machine.

The split used here is that the **native** perl from the build environment drives
`configure.pl`, `ExtUtils::xsubpp` and the ninja target generator, while the
**emscripten** perl is only ever compiled and linked against. Two consequences
are handled explicitly in `build.sh`:

- `build/perlx/*/*/config.ninja` is the single file describing the interpreter
  polymake compiles against. `configure.pl` fills it in from the native perl, so
  `build.sh` rewrites `CXXglueFLAGS` and `LIBperlFLAGS` to point at the target
  perl's `CORE` directory and `libperl.a`, reading the flags out of the target's
  `Config_heavy.pl`. `PERL` and the `xsubpp` path stay native — those are build
  tools, not link inputs.
- `AR` is taken from the native perl's config; it is overridden with `emar`,
  which is the only archiver that understands wasm objects.

`configure` also *runs* a compiled test program for nearly every dependency
(gmp, mpfr, flint, bliss, ppl, cddlib, lrslib, normaliz, libsingular).
Patch 0001 routes those through `POLYMAKE_TEST_RUNNER`, which `build.sh` sets to
`node`, so the probes genuinely run rather than failing as "cannot execute
binary file". Patch 0006 skips the `-fuse-ld=gold` probe, which is meaningless
when the linker is `wasm-ld`.

Upstream `configure.pl` refuses to run under perl ≥ 5.44, which is why the build
requirement is `perl >=5.16,<5.42`; the channel's variant pins the build perl to
5.32.1, comfortably inside polymake's supported range. The *target* perl being
5.44 does not matter, because it never runs `configure`.

## Limitations that are inherent, not bugs

- **No runtime C++ code generation.** When polymake meets a template
  instantiation it has no wrapper for, it normally writes C++ source, compiles it
  and dlopens the result. A wasm runtime has neither a compiler nor dynamic
  loading. Patch 0004 turns this into an explicit error instead of a confusing
  compiler-not-found failure. Only the instantiations baked in at build time are
  available. This is the single biggest behavioural difference from a native
  polymake, and the most likely thing a user will hit.
- **No interactive readline shell.** `Term::ReadLine::Gnu` and `Term::ReadKey`
  are XS modules and cannot be loaded. The driver implements its own line loop
  over `shell_execute` instead, so there is no completion or history.
- **No subprocesses.** The emscripten perl is patched to have no `fork`/`system`,
  so polymake's external visualization backends and anything else that shells out
  will not work.
- **`--config-path` defaults to `none`.** With the usual `user` setting polymake
  starts an interactive configuration wizard on first run, which nothing can
  answer in a non-interactive wasm runtime. Override with
  `POLYMAKE_CONFIG_PATH` if you have a writable home directory in the image.
- **Built for node, usable from a page.** `bin/polymake` is a shell launcher over
  `node bin/polymake.js`; `main()` runs on startup and `EXIT_RUNTIME=0` keeps the
  runtime alive afterwards, so `polymake_init`, `polymake_execute` and the other
  exported functions stay callable from JavaScript once the REPL has seen end of
  input. A browser page should set `Module.stdin = () => null` before startup,
  otherwise emscripten's default stdin reads through `window.prompt()`.

## Dependencies and bundled extensions

Everything polymake would normally vendor is taken from this channel instead,
which is why the source tarball is the "minimal" one:

| bundled extension | package   |
|-------------------|-----------|
| bliss             | `bliss`   |
| cdd               | `cddlib`  |
| flint             | `libflint`|
| lrs               | `lrslib`  |
| libnormaliz       | `normaliz` (+ `cocoalib`, `nauty`, which it links) |
| ppl               | `ppl`     |
| singular          | `singular` (+ `ntl`, `mathicgb`, `mathic`, `memtailor`) |

`atint` is enabled implicitly because `cdd` is. `permlib`, `TOSimplex` and
`Miniball` have no separate package and come from the tarball.

Disabled:

- **`nauty`** — polymake declares it `CONFLICT` with `bliss` in
  `bundled/nauty/polymake.ext`; both are alternative backends for
  `graph_compare`, and only one may be enabled. `bliss` is kept. The `nauty`
  *package* is still a host dependency, because `normaliz` links against it.
- `java`, `javaview` (need a JDK), `polydb` (needs mongoc, not in the channel),
  and `scip`, `soplex`, `sympol` — the latter three only to keep the first port's
  link surface small. `scip` and `soplex` **are** in the channel, so enabling them
  is just a matter of dropping the `--without-` flags and adding the packages to
  `host`.

`libxml2`, `libxslt`, `readline` and `ncurses` appear in polymake's INSTALL file
but are not linked by polymake itself — they are there for the XS perl modules
(`XML::LibXML`, `Term::ReadLine::Gnu`), which this build cannot use. They are
deliberately not listed as dependencies.

## Perl modules

polymake needs `JSON`, `XML::SAX`, `XML::Writer` and `SVG` at runtime. These are
pure perl and are shipped by the `perl` package in this channel (build 1 and
later), installed into `site_perl`, along with a `ParserDetails.ini` pointing
`XML::SAX::ParserFactory` at `XML::SAX::PurePerl`.

`Term::ReadKey` and `Term::ReadLine::Gnu`, which polymake's `configure` also
warns about, are XS and are not provided; `--without-prereq` suppresses the
warnings and nothing in this build path uses them.

## Singular

Singular is enabled, and needed three things beyond `--with-singular`. The
singular package itself is unmodified; everything lives on polymake's side.

**Its static library has unresolved externals.** `libSingular.a(semaphore.o)`
calls the POSIX *named* semaphore functions `sem_open`, `sem_unlink` and
`sem_getvalue`, which coordinate separate processes and which emscripten declares
but does not implement — a wasm module is one process with no `fork()`. The
singular package solves this for its own executable with `wasm_patch.c`, but
compiles that only into that binary, so every other consumer of `libSingular.a`
hits the same undefined symbols. `polymake_wasm_stubs.c` supplies equivalents:
the semaphore always opens and reports one free resource, so Singular's parallel
paths run as a single worker rather than failing to link. It is compiled before
configure and named in `LIBS`, which is what gets it into the singular probe as
well as the final link.

**Its transitive dependencies are not discoverable.** `libsingular-config --libs`
reports only `-lSingular -lpolys -lsingular_resources -lfactory -lomalloc`, and
`pkg-config --static --libs Singular` adds just NTL, but `libSingular.a` also
needs cddlib and mathicgb/mathic/memtailor. With shared libraries the loader
would follow those automatically; with archives they have to be named. The list
in `POLYMAKE_EXTRA_LIBS` was established by linking polymake's own singular probe
against the channel's packages until it resolved, which is also why `ntl`,
`mathicgb`, `mathic` and `memtailor` are host dependencies.

**It finds itself through `dladdr()`.** Both polymake's probe and its runtime
glue, `apps/ideal/src/singularInit.cc`, locate libsingular by asking `dladdr()`
for the shared object containing `siInit`, then hand that path to `siInit()`.
In a static binary there is no shared object and the call fails. Patch 0011:

- the probe skips that entirely when cross-compiling. It exists to establish that
  libsingular links and was built with NTL, which taking the address of `siInit`
  and reading `VERSION` does just as well — verified: it prints `Version: 4.4.1`,
  which is what polymake parses.
- `singularInit.cc` takes the path from `SINGULAR_EXECUTABLE` instead, under
  `#ifdef __EMSCRIPTEN__`, leaving the native path untouched.

That variable, and the rest of Singular's resource environment, is set by a
constructor in `polymake_wasm_stubs.c`. It has to be set from inside the program:
emscripten does not import the host environment, so `getenv` would otherwise
return nothing, and `siInit()` aborts with "Could not get expanded executable"
when it cannot resolve its resource tree. `build.sh` mounts the package's
`share/singular` at `/polymake/singular` in the filesystem image, so
`SINGULARPATH` points at the 222 `.lib` files. With those variables set,
`siInit()` succeeds in a static wasm binary.

What is *not* verified is polymake actually computing something through Singular:
that needs the finished binary.

## Static libraries and the bundled extension probes

polymake's bundled extension probes decide whether a dependency is usable by
looking for `lib<name>.$Config::Config{so}`. That is the shared-library suffix of
the perl **running configure** — the native one in a cross build — so on a
platform where every library is a static archive the file it names can never
exist, and the probe dies with "Invalid installation location" before it ever
compiles anything:

```
The bundled extension cdd was explicitly requested but failed to configure.
```

Every emscripten-forge package ships `.a` only. Patch 0008 adds an archive
fallback to the `cdd`, `flint`, `libnormaliz` and `ppl` probes, following the
shape the bundled `bliss` probe already uses — which is exactly why `bliss` was
the one extension that configured successfully before the patch. `lrs` and
`nauty` already accept `.a` upstream and needed no change. The fallbacks set no
rpath, since there is no shared object to find at runtime.

The `ppl` case also fixes an upstream bug: the branch read
`elsif ("$ppl_lib/libppl.a")`, a non-empty string and therefore always true, so
it rejected every installation without a shared library rather than testing for
the archive it named.

### Transitive dependencies

A shared `libflint.so` records a `DT_NEEDED` entry for libmpfr, and `libppl.so`
one for libgmpxx, so natively nobody has to name them. Static archives carry no
such records, and polymake's probes link only the direct library:

```
libflint.a(arf_merged.o): undefined symbol: mpfr_sqr
libppl.a: undefined symbol: operator<<(std::ostream&, __mpz_struct const*)
```

`build.sh` therefore passes `LIBS="-lgmpxx -lmpfr -lgmp"` to configure, which
appends it to every test program. wasm-ld resolves archives regardless of their
position on the command line, so naming them once suffices.

### Unflushed output from test programs

Emscripten does not flush stdio at exit unless `EXIT_RUNTIME=1`. The ppl probe
prints its version with no trailing newline, so it printed nothing; the warning
emscripten writes instead reached polymake's version comparison and broke its
`eval` with `Number found where operator expected ... near "to 1"` — the `to 1`
coming from "set EXIT_RUNTIME to 1" in that warning. Patch 0001 adds
`POLYMAKE_TEST_LDFLAGS`, applied to test programs only, and `build.sh` sets it to
`-sEXIT_RUNTIME=1 -sALLOW_MEMORY_GROWTH=1`. The final binary keeps
`EXIT_RUNTIME=0`, which is what lets an embedder call it after `main` returns.

## ninja must not re-run configure

ninja treats an output with no `.ninja_log` entry as dirty regardless of
timestamps, so the first build in a fresh directory re-runs configure. Here that
fails — replaying the saved command line rejects `--without-polydb` — and even if
it succeeded it would regenerate both `config.ninja` files from the native perl,
silently undoing the target-perl and `AR = emar` rewrites `build.sh` makes after
configure. Patch 0009 lets `POLYMAKE_NO_RECONFIGURE` turn the rule into a no-op,
and `build.sh` exports it before building.

## Compile and runtime failures in polymake itself

### Instantiation order in PuiseuxFraction

`apps/common/cpperl/generated/auto-det.cc` fails with

```
PuiseuxFraction.h:239: error: no viable overloaded '+='
RationalFunction.h:117: candidate template ignored: requirement
  'fits_as_particle<pm::RationalFunction<pm::Rational, long>>::value' was not satisfied
```

The statement is `rf += r.rf`, both sides the same `RationalFunction`, so the
plain member `operator+=(const RationalFunction&)` should match exactly — yet even
an explicitly qualified `rf.operator+=(r.rf)` sees only the template declared
before it. That is, the body is being instantiated while `RationalFunction` itself
is still mid-instantiation. It is not a wasm32 issue (it fails identically for
wasm64, where `long` is 64-bit) nor a language-mode issue (C++17 fails the same),
and small test programs doing the same arithmetic compile fine; it needs the full
wrapper translation unit to set up that instantiation order.

Patch 0010 routes the four `rf op= r.rf` statements in `PuiseuxFraction_generic`
through small function templates with explicit return types. Resolving a call to
one needs only its declaration, and its body is instantiated at the end of the
translation unit, when `RationalFunction` is complete. Behaviour is unchanged.
With it, `auto-det.cc` compiles.

### A default argument lost after an explicit specialization

`apps/common/cpperl/generated/auto-ext_gcd.cc` fails with

```
client.h:97: error: no member named 'add__me' in
  'pm::perl::FunctionWrapper<..., mlist<Canned<const UniPolynomial<Rational, long>&>,
                                        Canned<const UniPolynomial<Rational, long>&>>>'
```

which is misleading in two ways: `add__me` is inherited and plainly there, and
the real problem is not in `perl/wrappers.h` at all.

`FunctionWrapper` derives its result type with

```c++
using result_type = decltype(caller_t()(std::declval<arg_values>(), ...));
```

and that call ends up being `ext_gcd(a, b)`. `ext_gcd` is a function template
whose third parameter `bool normalize_gcd` has a default argument, and
`Polynomial.h` declares an explicit specialization of it for
`UniPolynomial<Rational, Int>` when polymake is built with FLINT — which this
recipe is. clang 21 then forgets the primary template's default argument, so the
two-argument call is ill-formed. Worse, it is rejected *only* in an unevaluated
operand, and without a diagnostic: the whole `using result_type = decltype(...)`
is dropped, the class loses every member that depends on it, and the first thing
that notices is the wrapper registration in the generated file.

The evidence, all reproducible against a single translation unit:

| expression | clang 21 |
| --- | --- |
| `ext_gcd(a, b)` as a statement | compiles |
| `decltype(ext_gcd(declval<const UniPolynomial<Rational,Int>&>(), ...))` | fails, silently |
| the same `decltype` with the third argument spelled out | compiles |
| the same `decltype` for `UniPolynomial<Integer,Int>` (no explicit specialization) | compiles |

g++ 13 accepts all four.

A default argument cannot be added to an explicit specialization, so patch 0012
drops the default from the primary template in `PolynomialImpl.h` and declares
the two-argument form as its own overload forwarding to the three-argument one.
Every existing call site keeps working, on every compiler, and no call now
depends on the default argument. A scan of the tree found `ext_gcd` to be the
only function template that has both a default argument and an explicit
specialization, so this is the only place the bug can bite.

### A non-const copy assignment operator, and libc++

`apps/common/cpperl/generated/auto-find_matrix_row_permutation.cc` fails with

```
libc++ __utility/pair.h:102: error: the parameter for this explicitly-defaulted
  copy assignment operator is const, but a member or base requires it to be non-const
  ... in instantiation of 'std::pair<const pm::sparse_matrix_line<...>, long>'
  ... in instantiation of 'find_permutation_impl<...>'
```

Unlike the other two this is not a compiler bug, and it is not specific to
clang: it is polymake meeting libc++ rather than libstdc++.

`sparse_matrix_line` declares

```c++
sparse_matrix_line& operator= (sparse_matrix_line& other)
```

with a **non-const** parameter. That makes the implicitly declared copy
assignment operator of any class holding a `sparse_matrix_line` take a non-const
reference too. `find_permutation_impl()` builds a
`Map<sparse_matrix_line<...>, Int>`, whose AVL nodes hold a
`std::pair<const sparse_matrix_line<...>, Int>` — and libc++ declares

```c++
pair& operator=(const pair&) ... = default;
```

whenever `_LIBCPP_ABI_TRIVIALLY_COPYABLE_PAIR` is in effect, which it is for ABI
version 2, the one emscripten ships. An explicitly defaulted copy assignment
operator must have the same parameter type as the implicit one would, so the two
declarations disagree and the pair fails to instantiate. libstdc++ writes its own
`operator=` rather than defaulting it, which is why this never shows up with gcc.

polymake's own `VectorChain` has the identical idiom one file over, written with
a const parameter:

```c++
VectorChain& operator= (const VectorChain& other) { return VectorChain::generic_type::operator=(other); }
```

and `GenericVector::operator=` takes its argument by const reference anyway, so
patch 0013 just makes `sparse_matrix_line` match: one word, `const`. It is the
only class in the tree with a non-const copy assignment operator.

### A bareword marker on a scalar that cannot hold it

With everything compiled and linked, the interpreter came up and then died in
`Polymake/Pipe.pm`:

```
unknown field type '' at /polymake/share/perllib/Polymake/Pipe.pm line 34
```

which is `use Polymake::Struct([ new => '$' ], ...)` with `new` arriving as undef.
It is not specific to `new`. Under `use namespaces`, any bareword to the left of a
fat comma loses itself, but only on the way into an array:

| construct | result |
| --- | --- |
| `my @a = ( key => 1 )` | `(undef, 1)` |
| `[ key => 1 ]` | `[undef, 1]` |
| `push @a, ( key => 1 )` | `(undef, 1)` |
| `my %h = ( key => 1 )` | correct |
| `f( key => 1 )` | correct |
| `( key => 1 )[0]` | correct |

`no namespaces` in the same file makes it correct again, and `B::Concise` shows
byte-identical op trees either way — same `const(PV "key") s/BARE`, same
`PL_ppaddr[OP_CONST]`. The difference is not in the tree at all.

`RefHash.xxs` replaces `pp_const` while the pragma is active, to mark barewords so
that polymake's `is_keyword()` can recognize them later:

```c
if ((PL_op->op_private & OPpCONST_BARE) && SvTYPE(sv) == SVt_PV)
   SvIsUV_on(sv);
```

`SVf_IVisUV` asserts that the scalar's IV slot holds a UV — and an `SVt_PV` has no
IV slot. Older perls ignored the flag on such a scalar; this one does not, and
copying it yields undef. That is exactly the difference between the two columns
above: a hash key is stringified in place, while an array assignment, an anonymous
array and `push` all *copy* the scalar.

polymake already does this marking correctly elsewhere — `get_cached_stash()` in
`lib/core/include/perl/Ext.h` upgrades to `SVt_PVIV` before setting the same flag.
Patch 0016 makes `intercept_pp_const` do the same. One `SvUPGRADE` call, and
polymake's whole perl library loads.

This was worth chasing rather than working around: the obvious workaround — quoting
the barewords in polymake's perl sources — needed 154 edits across 68 files, would
have missed `default =>` and friends further inside the same brackets, and would
have left every rules file and every user script exposed to the same trap.

## One packaging gotcha worth knowing

`variant.yaml` pins `perl: 5.32.1`. That is the conda-forge perl for the *build*
platform, but rattler-build applies a variant to any requirement written as a
bare name, in either environment. A bare `perl` under `host:` therefore resolves
to `perl 5.32.1.*` on emscripten-wasm32, where the only perl is 5.44.0, and the
host environment fails to solve before the build script ever runs:

```
Error: × Failed to resolve dependencies
  ╰─▶ Cannot solve the request because of: No candidates were found for perl 5.32.1.*.
```

Any explicit version suppresses the variant, which is why the host requirement
reads `perl >=5.44`. The same applies to any other emscripten-forge recipe that
host-depends on perl. The other variant-pinned host dependencies here —
`boost-cpp 1.87.0`, `libflint 3.6.0`, `gmp 6`, `mpfr 4` — all have matching
candidates in the channel, so they are fine left bare.

## Things to check first if the build fails

The patches and the configure flow have been verified against polymake 4.15; the
wasm link itself is the part with the least prior art, so in rough order of
likelihood:

1. **Stale headers, if you are rebuilding in place.** `${PREFIX}/include` is on
   every compile command ahead of polymake's own include directories, and
   `ninja install` copies polymake's headers into `${PREFIX}/include/polymake`.
   A second build in the same prefix then compiles against the *installed*
   headers, so an edit to `lib/core/include/...` has no effect and the failure
   makes no sense against the source you are reading. `build.sh` removes that
   directory before building for exactly this reason; if you drive ninja by hand,
   remove it yourself. Note also that ninja records those installed paths in its
   dependency log, so it will not even schedule a rebuild.
2. **Exception model mismatch.** Everything here is built with
   `-fwasm-exceptions`, matching the `ppl` package. If a prebuilt C++ dependency
   in the channel was built with the older Emscripten EH, the final link will
   complain — the flag is set in one place at the top of `build.sh`.
3. **Duplicate symbols at the final link.** `--allow-multiple-definition` is
   already passed. If something still collides, check that no fake/stub
   application library slipped into `APP_ARCHIVES`.
4. **XS compilation errors.** `ExtUtils::xsubpp` is the native perl's (5.32-ish)
   while the headers are 5.44's. Switching `ExtUtils_xsubpp` in the rewritten
   `perlx/config.ninja` to the target perl's copy is the first thing to try.
5. **Binary size.** polymake is large and `--whole-archive` defeats dead-code
   elimination by construction. If the result is unusably big, the lever is
   trimming the application set rather than the link flags.
