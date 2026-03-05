# Packaging Policy

This repository is packaging infrastructure, not an upstream source mirror.

## Rules

1. Keep one source RPM package per directory under `packages/<name>/`.
2. Keep package-specific patches under `packages/<name>/patches/`.
3. Use `Release: %autorelease` and `%autochangelog` unless there is a strong reason not to.
4. Keep the build path reproducible (`rpmbuild`, `mock`, COPR SCM + `make_srpm`).
5. Prefer explicit file ownership in specs and avoid broad globs where practical.
6. For Ghostty, keep conflict-prone terminfo aliases optional and disabled by default.

## Rollout strategy

1. Stabilize x86_64 first in COPR.
2. Expand to aarch64 once dependency closure is clean.
3. Add new source package directories only when there is a clear ownership boundary.
