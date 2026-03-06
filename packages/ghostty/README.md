# ghostty

Packaging directory for Ghostty and its VT developer library split.

## Binary package split from `ghostty.spec`

- `ghostty` - terminal emulator and user-facing assets
- `libghostty-vt` - shared VT/state library
- `libghostty-vt-devel` - headers, linker symlink, and pkg-config metadata

Themes are packaged separately in `packages/ghostty-themes`.

## Local build

```bash
make srpm
mock -r fedora-rawhide-x86_64 ../../dist/srpm/ghostty-*.src.rpm
```
