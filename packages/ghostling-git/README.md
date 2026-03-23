# ghostling-git

Snapshot packaging directory for Ghostling.

## Binary package split from `ghostling-git.spec`

- `ghostling-git` - minimal terminal demo that installs the `ghostling` binary

This package is intentionally a separate `-git` line until upstream starts
publishing tags/releases for Ghostling.

To stay buildable while Ghostling tracks newer Ghostty internals, the package
vendors the matching Ghostty snapshot source into the SRPM and links
`libghostty-vt` statically into the demo binary.

## Local build

```bash
make srpm
mock -r fedora-rawhide-x86_64 ../../dist/srpm/ghostling-git-*.src.rpm
```
