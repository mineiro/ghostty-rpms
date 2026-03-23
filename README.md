# ghostty-rpms

Fedora RPM packaging monorepo for Ghostty and related Ghostty developer
libraries.

This repository follows a multi-package layout (one source package directory
under `packages/`) so we can evolve the Ghostty stack over time without
rewriting repository tooling.

## Package map

| Source package dir   | Source spec       | Binary RPMs emitted today |
|----------------------|-------------------|----------------------------|
| `packages/ghostty`   | `ghostty.spec`    | `ghostty`, `libghostty-vt`, `libghostty-vt-devel` |
| `packages/ghostling-git` | `ghostling-git.spec` | `ghostling-git` |
| `packages/ghostty-themes` | `ghostty-themes.spec` | `ghostty-themes` |

`libghostty` (the larger embeddable runtime) is intentionally not emitted yet;
upstream currently treats it as unstable for general-purpose use.

## Layout

```text
.
├── .copr/              # COPR make_srpm integration
├── docs/               # Packaging policy and COPR setup notes
├── scripts/            # Shared helper scripts
└── packages/           # One source package per directory
```

## Quick start

Install baseline packaging tools:

```bash
sudo dnf install -y rpm-build rpmdevtools rpmlint mock copr-cli git jq curl
```

List packages:

```bash
make list
```

Parse/lint specs:

```bash
make check-specs
```

Build one SRPM:

```bash
make srpm PACKAGE=ghostty
```

Build all SRPMs:

```bash
make srpm-all
```

## Conflict note

By default, `ghostty.spec` drops the legacy `ghostty` terminfo alias to reduce
conflicts with other terminfo providers. The canonical `xterm-ghostty` entry is
still shipped.
