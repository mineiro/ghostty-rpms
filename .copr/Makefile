.PHONY: prepare srpm

# COPR passes `spec` and `outdir` when using SCM + make_srpm.
specfile = $(notdir $(spec))

prepare:
	dnf -y install --setopt=install_weak_deps=0 --nodocs git-core rpm-build rpmdevtools zstd

srpm: prepare
	@test -n "$(spec)" || { echo "COPR did not pass 'spec'"; exit 1; }
	@test -n "$(outdir)" || { echo "COPR did not pass 'outdir'"; exit 1; }
	@test -f "./$(specfile)" || { echo "Spec file not found in package directory: ./$(specfile)"; exit 1; }
	$(MAKE) srpm SPEC="./$(specfile)" OUTDIR="$(outdir)"
