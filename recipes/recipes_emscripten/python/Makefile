include ./Makefile.envs

ROOT=$(abspath .)

PYTHON_CFLAGS=$(CFLAGS_BASE) -DPY_CALL_TRAMPOLINE	

BUILD=$(ROOT)/build/${PKG_VERSION}/Python-${PKG_VERSION}
INSTALL=$(PREFIX)
LIB=libpython$(PYMAJOR).$(PYMINOR).a


all: $(INSTALL)/lib/$(LIB) 

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

LIBPYTHON_EXTRA_OBJECTS=$$(LIBMPDEC_OBJS) $$(LIBEXPAT_OBJS) $$(LIBHACL_SHA2_OBJS)

$(BUILD)/.patched_makefile:
	# Clear out libinstall deps (we build what we want explicitly first)
	cd $(BUILD) && sed -i -e 's/libinstall:.*/libinstall:/' Makefile;
	# Inject extra objects into libpython3.13.a so we don't have to link them
	# separately
	cd $(BUILD) && sed -i '/MODOBJS=/s/$$/ $(LIBPYTHON_EXTRA_OBJECTS)/' Makefile
	touch $(BUILD)/.patched_makefile

$(INSTALL)/lib/$(LIB): $(BUILD)/$(LIB) sysconfigdata $(BUILD)/.patched_makefile
	( \
		cd $(BUILD); \
		touch $(BUILD)/$(LIB) ; \
		emmake make PYTHON_FOR_BUILD=$(HOSTPYTHON) CROSS_COMPILE=yes inclinstall libinstall $(LIB) -j${CPU_COUNT} && \
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


$(BUILD)/Makefile: 
	# --enable-big-digits=30 :
	#   Python integers have "digits" of size 15 by default on systems with 32
	#   bit pointers and size 30 on systems with 16 bit pointers. Python uses
	#   "digits" of size 15 by default on systems with 32 bit pointers and size
	#   30 on systems with 16 bit pointers. WASM has 32 bit pointers so Python
	#   will default to the size 15 digits but WASM has native 64 bit arithmetic
	#   so it is more efficient to use 30 bit digits.
	( \
		cd $(BUILD); \
		CONFIG_SITE=./Tools/wasm/config.site-wasm32-emscripten READELF=true emconfigure \
		  ./configure \
			  CFLAGS="${PYTHON_CFLAGS} -I$(PREFIX)" \
			  CPPFLAGS="-sUSE_BZIP2=1 -sUSE_ZLIB=1 -I$(PREFIX)" \
			  PLATFORM_TRIPLET="$(PLATFORM_TRIPLET)" \
			  --without-pymalloc \
			  --disable-shared \
			  --disable-ipv6 \
			  --enable-big-digits=30 \
			  --enable-optimizations \
			  --host=wasm32-unknown-emscripten\
			  --build=$(shell $(BUILD)/config.guess) \
			  --prefix=$(INSTALL)  \
			  --with-build-python=$(BUILD_PREFIX)/bin/python \
	)


$(BUILD)/Modules/Setup.local: Setup.local
	cp Setup.local $(BUILD)/Modules/

$(BUILD)/$(LIB): $(BUILD)/Makefile $(BUILD)/pyconfig.h $(BUILD)/Modules/Setup.local 
	cp Setup.local $(BUILD)/Modules/
	( \
		cd $(BUILD); \
		make regen-frozen; \
		emmake make CROSS_COMPILE=yes $(LIB) -j${CPU_COUNT} \
	)
	touch $(BUILD)/$(LIB)
