SHELL := /bin/bash

SPEC ?= $(firstword $(wildcard *.spec))
OUTDIR ?= $(CURDIR)/../../dist/srpm
SOURCEDIR ?= $(CURDIR)/sources
PATCHDIR ?= $(CURDIR)/patches
GHOSTTY_COMMIT := $(shell awk '/^%global[[:space:]]+ghostty_commit[[:space:]]+/ {print $$3; exit}' "$(SPEC)")
ZIG_VERSION := $(shell awk '/^%global[[:space:]]+zig_version[[:space:]]+/ {print $$3; exit}' "$(SPEC)")
GHOSTTY_ARCHIVE := $(SOURCEDIR)/ghostty-$(GHOSTTY_COMMIT).tar.gz
ZIG_ARCHIVE_X86_64 := $(SOURCEDIR)/zig-x86_64-linux-$(ZIG_VERSION).tar.xz
ZIG_CACHE_ARCHIVE := $(SOURCEDIR)/ghostty-zig-cache-$(GHOSTTY_COMMIT).tar.zst

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

# The pinned Ghostty snapshot still relies on Zig package-manager fetches for
# libghostty-vt, so we vendor the transitive cache into the SRPM for offline
# mock/COPR builds.
#
# Since Zig 0.16 `zig fetch` leaves each package in the global cache as
# p/<hash>.tar.gz rather than an extracted p/<hash>/ directory, while
# `zig build --system` still expects directories. Unpack them before archiving.
# The loop is a no-op on Zig 0.15.x, which already extracts on fetch.
$(ZIG_CACHE_ARCHIVE): $(GHOSTTY_ARCHIVE) $(ZIG_ARCHIVE_X86_64)
	@tmpdir="$$(mktemp -d)"; \
	trap 'rm -rf "$$tmpdir"' EXIT; \
	tar -xzf "$(GHOSTTY_ARCHIVE)" -C "$$tmpdir"; \
	tar -xJf "$(ZIG_ARCHIVE_X86_64)" -C "$$tmpdir"; \
	srcroot="$$(find "$$tmpdir" -mindepth 1 -maxdepth 1 -type d -name 'ghostty-*' | head -n1)"; \
	[ -n "$$srcroot" ] || { echo "Could not find extracted ghostty source directory"; exit 1; }; \
	export PATH="$$tmpdir/zig-x86_64-linux-$(ZIG_VERSION):$$PATH"; \
	cd "$$srcroot"; \
	export ZIG_GLOBAL_CACHE_DIR="$$PWD/vendor"; \
	./nix/build-support/fetch-zig-cache.sh || exit 1; \
	for archive in vendor/p/*.tar.gz; do \
	  [ -e "$$archive" ] || continue; \
	  tar -xzf "$$archive" -C vendor/p || exit 1; \
	  dir="$${archive%.tar.gz}"; \
	  [ -d "$$dir" ] || { echo "Unexpected layout in $$archive"; exit 1; }; \
	  rm -f "$$archive"; \
	done; \
	compgen -G 'vendor/p/*/' >/dev/null \
	  || { echo "Vendored Zig cache has no package directories"; exit 1; }; \
	tar --zstd -cf "$(ZIG_CACHE_ARCHIVE)" vendor/p
