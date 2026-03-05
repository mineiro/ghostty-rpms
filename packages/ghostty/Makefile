SHELL := /bin/bash

SPEC ?= $(firstword $(wildcard *.spec))
OUTDIR ?= $(CURDIR)/../../dist/srpm
SOURCEDIR ?= $(CURDIR)/sources
PATCHDIR ?= $(CURDIR)/patches

.PHONY: srpm

srpm:
	@test -n "$(SPEC)" || { echo "No .spec file found"; exit 1; }
	@mkdir -p "$(OUTDIR)" "$(SOURCEDIR)"
	@if ls "$(PATCHDIR)"/*.patch >/dev/null 2>&1; then \
		cp -f "$(PATCHDIR)"/*.patch "$(SOURCEDIR)"/; \
	fi
	spectool -g -C "$(SOURCEDIR)" "$(SPEC)"
	rpmbuild -bs \
		--define "_sourcedir $(SOURCEDIR)" \
		--define "_specdir $(CURDIR)" \
		--define "_builddir $(CURDIR)" \
		--define "_srcrpmdir $(OUTDIR)" \
		--define "_rpmdir $(CURDIR)" \
		--define "_buildrootdir $(CURDIR)/.build" \
		"$(SPEC)"
