SWIFT  ?= swift
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
CONFIG ?= release

NATIVE = -Xswiftc -D -Xswiftc APLL_NATIVE

.PHONY: all core native install uninstall clean test

all: native

core:
	$(SWIFT) build -c $(CONFIG)

native:
	$(SWIFT) build -c $(CONFIG) $(NATIVE)

install: native
	install -d $(BINDIR)
	install -m 0755 .build/$(CONFIG)/apll $(BINDIR)/apll

uninstall:
	rm -f $(BINDIR)/apll

clean:
	$(SWIFT) package clean

test:
	$(SWIFT) test
	$(SWIFT) test $(NATIVE)
