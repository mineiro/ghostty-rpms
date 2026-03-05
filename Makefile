SHELL := /bin/bash

PACKAGES_DIR := $(CURDIR)/packages
OUTDIR ?= $(CURDIR)/dist/srpm
PACKAGE ?=

.PHONY: help list check-specs check-upstream srpm srpm-all

help:
	@echo "Targets:"
	@echo "  make list"
	@echo "  make check-specs"
	@echo "  make check-upstream [PACKAGE=<pkgname>]"
	@echo "  make srpm PACKAGE=<package-name> [OUTDIR=dist/srpm]"
	@echo "  make srpm-all [OUTDIR=dist/srpm]"

list:
	@find "$(PACKAGES_DIR)" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort

check-specs:
	@./scripts/check-specs.sh

check-upstream:
	@./scripts/check-upstream-versions.sh $(if $(PACKAGE),--package $(PACKAGE),)

srpm:
	@test -n "$(PACKAGE)" || { echo "PACKAGE is required"; exit 1; }
	@$(MAKE) -C "$(PACKAGES_DIR)/$(PACKAGE)" srpm OUTDIR="$(OUTDIR)"

srpm-all:
	@set -euo pipefail; \
	pkgs="$$(find "$(PACKAGES_DIR)" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"; \
	[ -n "$$pkgs" ] || { echo "No packages under $(PACKAGES_DIR)"; exit 0; }; \
	for pkg in $$pkgs; do \
	  echo "[srpm-all] $$pkg"; \
	  $(MAKE) -C "$(PACKAGES_DIR)/$$pkg" srpm OUTDIR="$(OUTDIR)"; \
	done
