include ./Makefile.envs

ROOT=$(abspath .)

PYTHON_CFLAGS=$(CFLAGS_BASE) -DPY_CALL_TRAMPOLINE	

BUILD=$(ROOT)/build/${PKG_VERSION}/Python-${PKG_VERSION}
INSTALL=$(PREFIX)
LIB=libpython$(PYMAJOR).$(PYMINOR).a


all: $(INSTALL)/lib/$(LIB) hacl

.PHONY=sysconfigdata
sysconfigdata:
	# Generate sysconfigdata. It outputs into a subfolder of build/, and
	# the subfolder is written to pybuilddir.txt.
	cd $(BUILD) && _PYTHON_SYSCONFIGDATA_NAME=$(SYSCONFIG_NAME) _PYTHON_PROJECT_BASE=$(BUILD) $(HOSTPYTHON) -m sysconfig --generate-posix-vars
	$(eval PYBUILDDIR=$(BUILD)/`cat $(BUILD)/pybuilddir.txt`)
	ROOT=$(ROOT) PYTHONPATH=$(PYBUILDDIR) python$(PYMAJOR).$(PYMINOR) adjust_sysconfig.py
	mkdir -p $(PREFIX)/lib/python$(PYMAJOR).$(PYMINOR)/
	mkdir -p $(SYSCONFIGDATA_DIR)
	cp $(PYBUILDDIR)/$(SYSCONFIG_NAME).py $(PREFIX)/lib/python$(PYMAJOR).$(PYMINOR)/
	cp $(PYBUILDDIR)/$(SYSCONFIG_NAME).py $(SYSCONFIGDATA_DIR)

# NOTE: this injection does not currently take effect. `emar t` on the
# libpython3.14.a inside the published python-3.14.3-h_7fd0122_0_cp314 lists
# no libmpdec, libexpat or HACL member, which is also why build.sh has to
# copy libmpdec.a and libexpat.a separately below. Left in place rather than
# removed, but nothing should be assumed to depend on it -- see the hacl
# target below, which does not.
LIBPYTHON_EXTRA_OBJECTS=$$(LIBMPDEC_OBJS) $$(LIBEXPAT_OBJS) $$(LIBHACL_SHA2_OBJS)

# HACL* hash primitives.
#
# libpython contains md5module.o, sha1module.o, sha2module.o, sha3module.o
# and blake2module.o, which reference the HACL* implementations as
# _Py_LibHacl_Hacl_Hash_*. Nothing in an Emscripten build produces those
# symbols, for two reasons that compound:
#
#   * configure only selects LIBHACL_LDEPS_LIBTYPE=STATIC for WASI (see
#     "HACL*-based cryptographic primitives" in configure.ac), so on
#     Emscripten the Modules/_hacl/libHacl_*.a archives are never a
#     prerequisite of anything and are never built;
#   * the SHARED alternative instead puts the HACL objects into
#     MODULE_<NAME>_LDFLAGS, which is read only by the rule that links a
#     *shared* extension module. Setup.local declares *static*, so the hash
#     modules go into MODOBJS and those LDFLAGS are never used.
#
# So libpython$(PYMAJOR).$(PYMINOR).a ships with 43 undefined
# _Py_LibHacl_Hacl_Hash_* symbols, and any link against it that pulls in a
# hash module -- which every link does, since these are builtin modules
# listed in PyImport_Inittab -- fails.
#
# The archive rules in CPython's Makefile are unconditional, so ask for them
# by name. libHacl_HMAC.a is left out: _hmac is disabled on Emscripten
# (python/cpython#133042) and the HMAC objects define none of the 43 symbols
# (SHA2 supplies 12, SHA3 9, Blake2s 6, Blake2b 6, SHA1 5, MD5 5).
HACL_LIBS= \
	Modules/_hacl/libHacl_Hash_MD5.a \
	Modules/_hacl/libHacl_Hash_SHA1.a \
	Modules/_hacl/libHacl_Hash_SHA2.a \
	Modules/_hacl/libHacl_Hash_SHA3.a \
	Modules/_hacl/libHacl_Hash_BLAKE2.a

.PHONY=hacl
hacl: $(INSTALL)/lib/$(LIB)
	cd $(BUILD) && \
		emmake make PYTHON_FOR_BUILD=$(HOSTPYTHON) CROSS_COMPILE=yes \
			$(HACL_LIBS) -j${CPU_COUNT}
	# Fold the objects into libpython, so that consumers linking -lpython
	# need no extra flags, and install the archives as well for anyone who
	# would rather link them explicitly.
	emar r $(INSTALL)/lib/$(LIB) $(BUILD)/Modules/_hacl/*.o
	cp $(BUILD)/Modules/_hacl/libHacl_*.a $(INSTALL)/lib/
	# Fail here rather than leaving every consumer of this package to
	# discover the gap as undefined symbols at link time.
	emar t $(INSTALL)/lib/$(LIB) | grep -q '^Hacl_Hash_SHA2.o$$'

$(BUILD)/.patched_makefile: $(BUILD)/Makefile
	# Clear out libinstall deps (we build what we want explicitly first)
	cd $(BUILD) && sed -i -e 's/libinstall:.*/libinstall:/' Makefile;
	# Disable HACL SIMD (x86-only) for wasm32 so portable Blake2 is used
	cd $(BUILD) && sed -i 's/^LIBHACL_BLAKE2_SIMD128_OBJS=.*/LIBHACL_BLAKE2_SIMD128_OBJS=/' Makefile && sed -i 's/^LIBHACL_BLAKE2_SIMD256_OBJS=.*/LIBHACL_BLAKE2_SIMD256_OBJS=/' Makefile
	# wasm_assets.py reads PYTHON_SYSCONFIGDATA_PATH in install step (patch 0009)
	# Inject extra objects into libpython3.14.a so we don't have to link them
	# separately
	cd $(BUILD) && sed -i '/MODOBJS=/s/$$/ $(LIBPYTHON_EXTRA_OBJECTS)/' Makefile
	touch $(BUILD)/.patched_makefile

$(INSTALL)/lib/$(LIB): $(BUILD)/$(LIB) sysconfigdata $(BUILD)/.patched_makefile
	( \
		cd $(BUILD); \
		sed -i -e 's/^LIBHACL_BLAKE2_SIMD128_OBJS=.*/LIBHACL_BLAKE2_SIMD128_OBJS=/' -e 's/^LIBHACL_BLAKE2_SIMD256_OBJS=.*/LIBHACL_BLAKE2_SIMD256_OBJS=/' Makefile; \
		sysconfigpath="$$(pwd)/$$(cat pybuilddir.txt)/$(SYSCONFIG_NAME).py"; \
		touch $(BUILD)/$(LIB) ; \
		_PYTHON_SYSCONFIGDATA_NAME=$(SYSCONFIG_NAME) PYTHON_SYSCONFIGDATA_PATH="$$sysconfigpath" emmake make PYTHON_FOR_BUILD=$(HOSTPYTHON) CROSS_COMPILE=yes inclinstall libinstall $(LIB) -j${CPU_COUNT} && \
		cp $(LIB) $(INSTALL)/lib/ \
	)
	# Generate sysconfigdata. It outputs into a subfolder of build/, and
	# the subfolder is written to pybuilddir.txt.
	_PYTHON_SYSCONFIGDATA_NAME=$(SYSCONFIG_NAME) _PYTHON_PROJECT_BASE=$(BUILD) $(HOSTPYTHON) -m sysconfig --generate-posix-vars

	$(eval PYBUILDDIR=`cat pybuilddir.txt`)
	PYTHONPATH=$(PYBUILDDIR) python adjust_sysconfig.py
	cp $(PYBUILDDIR)/$(SYSCONFIG_NAME).py $(INSTALL)/lib/python$(PYMAJOR).$(PYMINOR)/
	mkdir -p $(SYSCONFIGDATA_DIR)
	cp $(PYBUILDDIR)/$(SYSCONFIG_NAME).py $(SYSCONFIGDATA_DIR)
	rm -rf $(PYBUILDDIR)
	rm pybuilddir.txt


clean:
	-rm -fr $(ROOT)/build
	-rm -fr $(ROOT)/installs

clean-all: clean
	-rm -fr $(ROOT)/downloads


$(BUILD)/.patched: 
#	[ -d $(BUILD) ] || $(error "No python version has been downloaded from the build recipe!")
	cat patches/*.patch | (cd $(BUILD) ; patch -p1)
	touch $@


$(BUILD)/Makefile: $(BUILD)/Modules/Setup.local
	# --enable-big-digits=30 :
	#   Python integers have "digits" of size 15 by default on systems with 32
	#   bit pointers and size 30 on systems with 16 bit pointers. Python uses
	#   "digits" of size 15 by default on systems with 32 bit pointers and size
	#   30 on systems with 16 bit pointers. WASM has 32 bit pointers so Python
	#   will default to the size 15 digits but WASM has native 64 bit arithmetic
	#   so it is more efficient to use 30 bit digits.
	cp Setup.local $(BUILD)/Modules/
	( \
		cd $(BUILD); \
		echo 'ac_cv_lib_uuid_uuid_generate_time_safe=no' >> ./Tools/wasm/config.site-wasm32-emscripten; \
		echo 'have_uuid=no' >> ./Tools/wasm/config.site-wasm32-emscripten; \
		ac_cv_header_fcntl_h=yes ac_cv_func_fcntl=yes \
		ac_cv_func_mbstowcs=yes ac_cv_broken_mbstowcs=yes \
		ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no \
		ac_cv_func_memfd_create=no \
		CONFIG_SITE=./Tools/wasm/config.site-wasm32-emscripten READELF=true emconfigure \
		  ./configure \
			  CFLAGS="${PYTHON_CFLAGS} -I$(PREFIX)" \
			  CPPFLAGS="-sUSE_BZIP2=1 -sUSE_ZLIB=1 -I$(PREFIX)" \
			  LDFLAGS="-L$(PREFIX)/lib" \
			  PLATFORM_TRIPLET="$(PLATFORM_TRIPLET)" \
			  --without-pymalloc \
			  --disable-shared \
			  --disable-ipv6 \
			  --enable-big-digits=30 \
			  --host=wasm32-unknown-emscripten\
			  --build=$(shell $(BUILD)/config.guess) \
			  --prefix=$(INSTALL)  \
			  --with-build-python=$(BUILD_PREFIX)/bin/python \
		; \
		sed -i 's/^LIBHACL_BLAKE2_SIMD128_OBJS=.*/LIBHACL_BLAKE2_SIMD128_OBJS=/' Makefile \
		; sed -i 's/^LIBHACL_BLAKE2_SIMD256_OBJS=.*/LIBHACL_BLAKE2_SIMD256_OBJS=/' Makefile \
		)


$(BUILD)/Modules/Setup.local: Setup.local
	cp Setup.local $(BUILD)/Modules/

$(BUILD)/$(LIB): $(BUILD)/Makefile $(BUILD)/pyconfig.h $(BUILD)/Modules/Setup.local $(BUILD)/.patched_makefile
	cp Setup.local $(BUILD)/Modules/
	( \
		cd $(BUILD); \
		sed -i -e 's/^LIBHACL_BLAKE2_SIMD128_OBJS=.*/LIBHACL_BLAKE2_SIMD128_OBJS=/' -e 's/^LIBHACL_BLAKE2_SIMD256_OBJS=.*/LIBHACL_BLAKE2_SIMD256_OBJS=/' Makefile; \
		make regen-frozen; \
		PREFIX=$(PREFIX) emmake make PYTHON_FOR_BUILD=$(HOSTPYTHON) CROSS_COMPILE=yes $(LIB) -j${CPU_COUNT} \
	)
	touch $(BUILD)/$(LIB)
