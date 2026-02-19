## Copyright 2015-2016 Carnë Draug
## Copyright 2015-2016 Oliver Heimlich
##
## Copying and distribution of this file, with or without modification,
## are permitted in any medium without royalty provided the copyright
## notice and this notice are preserved.  This file is offered as-is,
## without any warranty.

PACKAGE := $(shell grep "^Name: " DESCRIPTION | cut -f2 -d" ")
VERSION := $(shell grep "^Version: " DESCRIPTION | cut -f2 -d" ")

TARGET_DIR      := target
RELEASE_DIR     := $(TARGET_DIR)/$(PACKAGE)-$(VERSION)
RELEASE_TARBALL := $(TARGET_DIR)/$(PACKAGE)-$(VERSION).tar.gz
HTML_DIR        := $(TARGET_DIR)/$(PACKAGE)-html
HTML_TARBALL    := $(TARGET_DIR)/$(PACKAGE)-html.tar.gz

M_SOURCES   := $(wildcard inst/*.m)
CC_SOURCES  := $(wildcard src/*.cc)
OCT_FILES   := $(patsubst %.cc,%.oct,$(CC_SOURCES))

#OCTAVE ?= octave --no-window-system --silent
# remove --no-window-system in order to use "qt" graphics toolkit
OCTAVE ?= octave --silent
MKOCTFILE ?= mkoctfile

PWD != pwd
## Command line arguments to use when calling Octave.
PATH_ARGS = --path '$(PWD)/inst/' --path '$(PWD)/src/'

.PHONY: help dist html release install all check run clean

help:
	@echo "Targets:"
	@echo "   dist    - Create $(RELEASE_TARBALL) for release"
	@echo "   html    - Create $(HTML_TARBALL) for release"
	@echo "   release - Create both of the above and show md5sums"
	@echo
	@echo "   install - Install the package in GNU Octave"
	@echo "   all     - Build all oct files"
	@echo "   check   - Execute package tests (w/o install)"
	@echo "   doctest - Tests only the help text via the doctest package"
	@echo "   run     - Run Octave with development in PATH (no install)"
	@echo
	@echo "   clean   - Remove releases, html documentation, and oct files"

%.tar.gz: %
	tar -c -f - --posix -C "$(TARGET_DIR)/" "$(notdir $<)" | gzip -9n > "$@"

$(RELEASE_DIR): .hg/dirstate
	@echo "Creating package version $(VERSION) release ..."
	$(RM) -r "$@"
	hg archive --exclude ".hg*" --exclude "Makefile" --exclude "HACKING" \
	  --exclude "devel" --type files "$@"
	cd "$@" && ./bootstrap && rm -rf "src/autom4te.cache"
	$(RM) "$@/bootstrap"
	chmod -R a+rX,u+w,go-w "$@"

$(HTML_DIR): install
	@echo "Generating HTML documentation. This may take a while ..."
	$(RM) -r "$@"
#       $(OCTAVE) --no-window-system --silent
#       remove --no-window-system in order to use "qt" graphics toolkit
	$(OCTAVE) --silent \
	  --eval "pkg load generate_html; " \
	  --eval "pkg load $(PACKAGE);" \
	  --eval 'generate_package_html ("${PACKAGE}", "$@", "octave-forge");'
	chmod -R a+rX,u+w,go-w $@

dist: $(RELEASE_TARBALL)
html: $(HTML_TARBALL)

release: dist html
	md5sum $(RELEASE_TARBALL) $(HTML_TARBALL)
	@echo "Upload @ https://sourceforge.net/p/octave/package-releases/new/"
	@echo 'Execute: hg tag "release-${VERSION}"'

## Note that in development versions this target may fail if we are dependent
## on unreleased versions.  This is by design, to force possible developers
## to set this up by hand (either using the "-nodeps" option" or changing the
## dependencies on DESCRIPTION.
install: $(RELEASE_TARBALL)
	@echo "Installing package locally ..."
	$(OCTAVE) --eval 'pkg ("install", "-verbose", "${RELEASE_TARBALL}")'

all: $(CC_SOURCES)
	cd src/ && ./configure
	$(MAKE) -C src/

check: all
	$(OCTAVE) ${PATH_ARGS} \
          --eval "run_pkg_add ();"\
	  --eval 'oruntests ("inst"); oruntests ("src");'

doctest: all
	$(OCTAVE) ${PATH_ARGS} \
          --eval "run_pkg_add ();"\
	  --eval 'pkg load doctest;' \
	  --eval "targets = '$(shell (ls inst; ls src | $(GREP) .oct) | cut -f2 -d@ | cut -f1 -d.)';" \
	  --eval "targets = strsplit (targets, ' ');" \
	  --eval "doctest (targets);"

run: all
	$(OCTAVE) --persist ${PATH_ARGS} \
          --eval "run_pkg_add ();"

clean:
	$(RM) -r $(TARGET_DIR)
	test ! -e src/Makefile || $(MAKE) -C src clean
	cd src/ && $(RM) config.h config.log config.status configure Makefile