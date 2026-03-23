# COPR Setup

This repo is designed for COPR `SCM` entries with `make_srpm`.

## Recommended project settings

- Clone URL: your fork URL for this repository
- Committish: `main`
- Source type: `SCM`
- Build SRPM with: `make_srpm`

## Current public project

The current public COPR project for this repository is `mineiro/ghostty`.

## Add package entries

Add one SCM package entry per subdirectory:

- Package name: `ghostty`
- Subdirectory: `packages/ghostty`
- Spec file: `ghostty.spec`

- Package name: `ghostty-themes`
- Subdirectory: `packages/ghostty-themes`
- Spec file: `ghostty-themes.spec`

- Package name: `ghostling-git`
- Subdirectory: `packages/ghostling-git`
- Spec file: `ghostling-git.spec`

## Suggested chroots

- `fedora-43-x86_64`
- `fedora-44-x86_64`
- `fedora-rawhide-x86_64`
- `fedora-43-aarch64`
- `fedora-44-aarch64`
- `fedora-rawhide-aarch64`
