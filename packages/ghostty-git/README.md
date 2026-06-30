# ghostty-git

Experimental main-branch snapshot packaging for Ghostty.

This package tracks upstream `ghostty-org/ghostty` `HEAD` and is intended for
testing unreleased changes from COPR. It installs the normal `ghostty` binary
and desktop assets, so it conflicts with the stable `ghostty` package.

## Binary package split from `ghostty-git.spec`

- `ghostty-git` - terminal emulator and user-facing assets from upstream main
- `libghostty-vt-git` - shared VT/state library from the same snapshot
- `libghostty-vt-git-devel` - headers, linker symlink, and pkg-config metadata

The `-git` packages provide the corresponding stable package names so dependency
solving works, but they intentionally do not obsolete stable packages.

## Local build

```bash
make srpm
mock -r fedora-rawhide-x86_64 ../../dist/srpm/ghostty-git-*.src.rpm
```
