#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mapfile -t specs < <(find "${repo_root}/packages" -type f -name '*.spec' | sort)

if [[ ${#specs[@]} -eq 0 ]]; then
  echo "No spec files found under packages/ (nothing to check yet)."
  exit 0
fi

if ! command -v rpmspec >/dev/null 2>&1; then
  echo "rpmspec not found; install rpm-build"
  exit 1
fi

echo "Parsing spec files..."
for spec in "${specs[@]}"; do
  rpmspec -P "${spec}" >/dev/null
  echo "OK  ${spec#${repo_root}/}"
done

if command -v rpmlint >/dev/null 2>&1; then
  echo
  echo "Running rpmlint..."
  rpmlint "${specs[@]}"
else
  echo
  echo "rpmlint not installed; skipping lint phase"
fi
