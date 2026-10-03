PREFIX ?= /usr/local
DESTDIR ?=

BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib/woche
MANDIR := $(PREFIX)/share/man/man1
COMPLETIONDIR := $(PREFIX)/share/bash-completion/completions

VERSION := $(shell sed -n 's/^export WOCHE_VERSION="\(.*\)"/\1/p' variables.sh)
# Same sources, same .deb: file times come from the last commit
export SOURCE_DATE_EPOCH ?= $(shell git log -1 --format=%ct 2> /dev/null)
SCRIPTS := woche.sh functions.sh variables.sh tests.sh completions/woche.bash

.PHONY: all install uninstall test lint deb clean

all: build/woche.1.gz

build/woche.1.gz: man/woche.1
	mkdir -p build
	gzip -9 -n -c man/woche.1 > $@

install: build/woche.1.gz
	install -d "$(DESTDIR)$(LIBDIR)" "$(DESTDIR)$(BINDIR)" "$(DESTDIR)$(MANDIR)" "$(DESTDIR)$(COMPLETIONDIR)"
	install -m 755 woche.sh "$(DESTDIR)$(LIBDIR)/woche.sh"
	install -m 644 functions.sh variables.sh "$(DESTDIR)$(LIBDIR)/"
	ln -sfr "$(DESTDIR)$(LIBDIR)/woche.sh" "$(DESTDIR)$(BINDIR)/woche"
	install -m 644 build/woche.1.gz "$(DESTDIR)$(MANDIR)/woche.1.gz"
	install -m 644 completions/woche.bash "$(DESTDIR)$(COMPLETIONDIR)/woche"

uninstall:
	rm -f "$(DESTDIR)$(BINDIR)/woche" "$(DESTDIR)$(MANDIR)/woche.1.gz" "$(DESTDIR)$(COMPLETIONDIR)/woche"
	rm -rf "$(DESTDIR)$(LIBDIR)"

test:
	bash tests.sh

lint:
	shellcheck -x --severity=warning $(SCRIPTS)

# Needs nfpm (https://nfpm.goreleaser.com)
deb: build/woche.1.gz
	$(if $(VERSION),,$(error Could not read WOCHE_VERSION from variables.sh))
	mkdir -p dist
	VERSION=$(VERSION) nfpm package --config nfpm.yaml --packager deb --target dist/

clean:
	rm -rf build dist
