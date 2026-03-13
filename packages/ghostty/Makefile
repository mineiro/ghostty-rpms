SHELL := /bin/bash

SPEC ?= $(firstword $(wildcard *.spec))
OUTDIR ?= $(CURDIR)/../../dist/srpm
SOURCEDIR ?= $(CURDIR)/sources
PATCHDIR ?= $(CURDIR)/patches
VERSION := $(shell awk '/^Version:[[:space:]]+/ {print $$2; exit}' "$(SPEC)")
ZIG_VERSION := $(shell awk '/^%global[[:space:]]+zig_version[[:space:]]+/ {print $$3; exit}' "$(SPEC)")
SOURCE_ARCHIVE := $(SOURCEDIR)/ghostty-$(VERSION).tar.gz
ZIG_ARCHIVE_X86_64 := $(SOURCEDIR)/zig-x86_64-linux-$(ZIG_VERSION).tar.xz
ZIG_CACHE_ARCHIVE := $(SOURCEDIR)/ghostty-zig-cache-$(VERSION).tar.zst

.PHONY: srpm zig-cache

srpm:
	@test -n "$(SPEC)" || { echo "No .spec file found"; exit 1; }
	@mkdir -p "$(OUTDIR)" "$(SOURCEDIR)"
	@if ls "$(PATCHDIR)"/*.patch >/dev/null 2>&1; then \
		cp -f "$(PATCHDIR)"/*.patch "$(SOURCEDIR)"/; \
	fi
	spectool -g -C "$(SOURCEDIR)" "$(SPEC)"
	$(MAKE) zig-cache
	rpmbuild -bs \
		--define "_sourcedir $(SOURCEDIR)" \
		--define "_specdir $(CURDIR)" \
		--define "_builddir $(CURDIR)" \
		--define "_srcrpmdir $(OUTDIR)" \
		--define "_rpmdir $(CURDIR)" \
		--define "_buildrootdir $(CURDIR)/.build" \
		"$(SPEC)"

zig-cache: $(ZIG_CACHE_ARCHIVE)

# Ghostty release tarballs still rely on Zig package-manager fetches at build
# time, so we vendor the transitive cache into the SRPM for offline mock/COPR builds.
$(ZIG_CACHE_ARCHIVE): $(SOURCE_ARCHIVE) $(ZIG_ARCHIVE_X86_64)
	@tmpdir="$$(mktemp -d)"; \
	trap 'rm -rf "$$tmpdir"' EXIT; \
	tar -xzf "$(SOURCE_ARCHIVE)" -C "$$tmpdir"; \
	tar -xJf "$(ZIG_ARCHIVE_X86_64)" -C "$$tmpdir"; \
	cd "$$tmpdir/ghostty-$(VERSION)"; \
	export PATH="$$tmpdir/zig-x86_64-linux-$(ZIG_VERSION):$$PATH"; \
	export ZIG_GLOBAL_CACHE_DIR="$$PWD/vendor"; \
	./nix/build-support/fetch-zig-cache.sh; \
	tar --zstd -cf "$(ZIG_CACHE_ARCHIVE)" vendor/p
