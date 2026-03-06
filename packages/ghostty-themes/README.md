# ghostty-themes

Packaging directory for Ghostty color themes as a separate source package.

## Binary package split from `ghostty-themes.spec`

- `ghostty-themes` - optional Ghostty theme files installed under `/usr/share/ghostty/themes`

## Notes

- The source archive is a Ghostty-hosted snapshot of the theme collection used
  by upstream builds.
- This package is intentionally separate from `ghostty.spec` so the main
  Ghostty build does not need theme sources at all.

## Local build

```bash
make srpm
mock -r fedora-rawhide-x86_64 ../../dist/srpm/ghostty-themes-*.src.rpm
```
