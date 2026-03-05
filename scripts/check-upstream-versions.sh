#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-upstream-versions.sh [--package <name>]
USAGE
}

package_filter=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package)
      package_filter="${2:-}"
      [[ -n "${package_filter}" ]] || { echo "--package requires a value"; exit 1; }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

for cmd in git awk; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd not found"; exit 1; }
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -n "${package_filter}" ]]; then
  env_files=("${repo_root}/packages/${package_filter}/package.env")
else
  mapfile -t env_files < <(find "${repo_root}/packages" -mindepth 2 -maxdepth 2 -type f -name package.env | sort)
fi

if [[ ${#env_files[@]} -eq 0 ]]; then
  echo "No package.env files found under packages/"
  exit 0
fi

if [[ -n "${package_filter}" && ! -f "${env_files[0]}" ]]; then
  echo "Package not found: ${package_filter}"
  exit 1
fi

printf '%-24s %-14s %-14s %-10s %s\n' "PACKAGE" "LOCAL" "UPSTREAM" "STATUS" "UPSTREAM_GIT"

for envf in "${env_files[@]}"; do
  pkg_dir="$(dirname "${envf}")"
  pkg_name="$(basename "${pkg_dir}")"

  spec_file="$(awk -F= '/^SPEC_FILE=/{print $2}' "${envf}")"
  upstream_git="$(awk -F= '/^UPSTREAM_GIT=/{print $2}' "${envf}")"

  if [[ -z "${spec_file}" || -z "${upstream_git}" ]]; then
    printf '%-24s %-14s %-14s %-10s %s\n' "${pkg_name}" "(invalid)" "(unknown)" "unknown" "${upstream_git:-N/A}"
    continue
  fi

  spec_path="${pkg_dir}/${spec_file}"
  if [[ ! -f "${spec_path}" ]]; then
    printf '%-24s %-14s %-14s %-10s %s\n' "${pkg_name}" "(missing)" "(unknown)" "unknown" "${upstream_git}"
    continue
  fi

  local_version="$(awk '/^Version:[[:space:]]+/{print $2; exit}' "${spec_path}")"
  upstream_tag="$(
    git ls-remote --tags --refs "${upstream_git}" 2>/dev/null \
      | awk -F/ '{print $NF}' \
      | grep -E '^[vV]?[0-9]+(\.[0-9]+){1,3}([._-][0-9A-Za-z.-]+)?$' \
      | sort -V \
      | tail -n1 || true
  )"
  upstream_version="${upstream_tag#v}"

  if [[ -z "${upstream_tag}" ]]; then
    status="unknown"
    upstream_version="(unknown)"
  elif [[ "${local_version}" == "${upstream_version}" ]]; then
    status="same"
  else
    status="different"
  fi

  printf '%-24s %-14s %-14s %-10s %s\n' "${pkg_name}" "${local_version}" "${upstream_version}" "${status}" "${upstream_git}"
done
