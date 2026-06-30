#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-ghostty-git.sh

Updates packages/ghostty-git to the current upstream Ghostty HEAD.
If the local commit already matches upstream, no files are changed.

When GITHUB_OUTPUT is set, writes:
  changed, commit, short_commit, commit_date, version, upstream_version, zig_version
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for cmd in awk curl git sed; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd not found" >&2; exit 1; }
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg_dir="${repo_root}/packages/ghostty-git"
spec="${pkg_dir}/ghostty-git.spec"
env_file="${pkg_dir}/package.env"

read_env() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key {print $2; exit}' "$env_file"
}

read_spec_macro() {
  local macro_name="$1"
  awk -v macro_name="$macro_name" '$1 == "%global" && $2 == macro_name {print $3; exit}' "$spec"
}

set_spec_macro() {
  local macro_name="$1"
  local value="$2"
  grep -Eq "^%global[[:space:]]+${macro_name}[[:space:]]+" "$spec" || {
    echo "Missing spec macro: ${macro_name}" >&2
    exit 1
  }
  sed -i -E "s|^%global[[:space:]]+${macro_name}[[:space:]]+.*$|%global ${macro_name} ${value}|" "$spec"
}

set_env_value() {
  local key="$1"
  local value="$2"
  if grep -Eq "^${key}=" "$env_file"; then
    sed -i -E "s|^${key}=.*$|${key}=${value}|" "$env_file"
  else
    printf '%s=%s\n' "$key" "$value" >>"$env_file"
  fi
}

github_repo_from_url() {
  local url="$1"
  sed -E 's#^https://github.com/([^/]+/[^/.]+)(\.git)?/?$#\1#' <<<"$url"
}

github_commit_date() {
  local repo="$1"
  local commit="$2"
  curl -fsSL "https://api.github.com/repos/${repo}/commits/${commit}" \
    | sed -n 's/.*"date": "\([0-9-]\+\)T.*/\1/p' \
    | head -n1 \
    | tr -d '-'
}

raw_github_url() {
  local repo="$1"
  local commit="$2"
  local path="$3"
  printf 'https://raw.githubusercontent.com/%s/%s/%s' "$repo" "$commit" "$path"
}

github_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
}

upstream_git="$(read_env "UPSTREAM_GIT")"
github_repo="$(github_repo_from_url "$upstream_git")"
[[ -n "$upstream_git" && -n "$github_repo" ]] || {
  echo "Could not derive GitHub repo from UPSTREAM_GIT=${upstream_git}" >&2
  exit 1
}

local_commit="$(read_spec_macro "commit")"
head_commit="$(git ls-remote "$upstream_git" HEAD 2>/dev/null | awk '{print $1}')"
[[ -n "$head_commit" ]] || { echo "Could not resolve upstream HEAD" >&2; exit 1; }

if [[ "$local_commit" == "$head_commit" ]]; then
  echo "ghostty-git is already current at ${head_commit:0:7}"
  github_output "changed" "false"
  github_output "commit" "$head_commit"
  github_output "short_commit" "${head_commit:0:7}"
  github_output "version" "$(awk '/^Version:[[:space:]]+/ {print $2; exit}' "$spec")"
  exit 0
fi

commit_date="$(github_commit_date "$github_repo" "$head_commit")"
[[ -n "$commit_date" ]] || { echo "Could not resolve commit date for $head_commit" >&2; exit 1; }

zon_url="$(raw_github_url "$github_repo" "$head_commit" "build.zig.zon")"
zon="$(curl -fsSL "$zon_url")"
upstream_version="$(
  sed -n 's/.*\.version = "\([^"]*\)".*/\1/p' <<<"$zon" | head -n1
)"
zig_version="$(
  sed -n 's/.*\.minimum_zig_version = "\([^"]*\)".*/\1/p' <<<"$zon" | head -n1
)"
[[ -n "$upstream_version" ]] || { echo "Could not read upstream version from build.zig.zon" >&2; exit 1; }
[[ -n "$zig_version" ]] || { echo "Could not read minimum Zig version from build.zig.zon" >&2; exit 1; }

short_commit="${head_commit:0:7}"
base_version="${upstream_version%%+*}"
base_version="${base_version%%-*}"
rpm_version="${base_version}.${commit_date}git${short_commit}"

set_spec_macro "zig_version" "$zig_version"
set_spec_macro "upstream_version" "${upstream_version%%+*}"
set_spec_macro "commit" "$head_commit"
set_spec_macro "shortcommit" "$short_commit"
set_spec_macro "commitdate" "$commit_date"
sed -i -E "s|^Version:[[:space:]]+.*$|Version:        ${rpm_version}|" "$spec"
set_env_value "UPSTREAM_BASE_VERSION" "$base_version"

echo "Updated ghostty-git: ${local_commit:0:7} -> ${short_commit} (${rpm_version})"
github_output "changed" "true"
github_output "commit" "$head_commit"
github_output "short_commit" "$short_commit"
github_output "commit_date" "$commit_date"
github_output "version" "$rpm_version"
github_output "upstream_version" "${upstream_version%%+*}"
github_output "zig_version" "$zig_version"
