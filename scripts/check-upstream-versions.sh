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

for cmd in curl sed; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd not found"; exit 1; }
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

read_env() {
  local env_file="$1"
  local key="$2"
  awk -F= -v key="$key" '$1 == key {print $2; exit}' "$env_file"
}

read_spec_macro() {
  local spec_file="$1"
  local macro_name="$2"
  awk -v macro_name="$macro_name" '$1 == "%global" && $2 == macro_name {print $3; exit}' "$spec_file"
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

extract_theme_snapshot_name() {
  local manifest_url="$1"
  curl -fsSL "$manifest_url" \
    | sed -n 's#.*https://deps\.files\.ghostty\.org/\(ghostty-themes-release-[^"]*\.tgz\).*#\1#p' \
    | head -n1
}

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

printf '%-24s %-22s %-22s %-10s %s\n' "PACKAGE" "LOCAL" "UPSTREAM" "STATUS" "SOURCE"

for envf in "${env_files[@]}"; do
  pkg_dir="$(dirname "${envf}")"
  pkg_name="$(basename "${pkg_dir}")"

  spec_file="$(read_env "${envf}" "SPEC_FILE")"
  upstream_git="$(read_env "${envf}" "UPSTREAM_GIT")"
  upstream_strategy="$(read_env "${envf}" "UPSTREAM_VERSION_STRATEGY")"
  upstream_strategy="${upstream_strategy:-git_tag}"

  if [[ -z "${spec_file}" || -z "${upstream_git}" ]]; then
    printf '%-24s %-22s %-22s %-10s %s\n' "${pkg_name}" "(invalid)" "(unknown)" "unknown" "${upstream_git:-N/A}"
    continue
  fi

  spec_path="${pkg_dir}/${spec_file}"
  if [[ ! -f "${spec_path}" ]]; then
    printf '%-24s %-22s %-22s %-10s %s\n' "${pkg_name}" "(missing)" "(unknown)" "unknown" "${upstream_git}"
    continue
  fi

  local_version="$(awk '/^Version:[[:space:]]+/{print $2; exit}' "${spec_path}")"
  upstream_version="(unknown)"
  status="unknown"
  source_hint="${upstream_git}"

  case "${upstream_strategy}" in
    git_tag)
      upstream_tag="$(
        git ls-remote --tags --refs "${upstream_git}" 2>/dev/null \
          | awk -F/ '{print $NF}' \
          | grep -E '^[vV]?[0-9]+(\.[0-9]+){1,3}([._-][0-9A-Za-z.-]+)?$' \
          | sort -V \
          | tail -n1 || true
      )"
      upstream_version="${upstream_tag#v}"
      source_hint="${upstream_git}"

      if [[ -n "${upstream_tag}" ]]; then
        if [[ "${local_version}" == "${upstream_version}" ]]; then
          status="same"
        else
          status="different"
        fi
      fi
      ;;
    git_head_snapshot)
      github_repo="$(github_repo_from_url "${upstream_git}")"
      head_commit="$(git ls-remote "${upstream_git}" HEAD 2>/dev/null | awk '{print $1}')"
      local_commit_macro="$(read_env "${envf}" "SPEC_COMMIT_MACRO")"
      base_version="$(read_env "${envf}" "UPSTREAM_BASE_VERSION")"
      local_commit_macro="${local_commit_macro:-commit}"
      base_version="${base_version:-0.0}"
      local_commit="$(read_spec_macro "${spec_path}" "${local_commit_macro}")"

      if [[ -n "${head_commit}" && -n "${github_repo}" ]]; then
        head_date="$(github_commit_date "${github_repo}" "${head_commit}")"
        if [[ -n "${head_date}" ]]; then
          upstream_version="${base_version}.${head_date}git${head_commit:0:7}"
          source_hint="${upstream_git}@${head_commit:0:7}"
          if [[ "${local_commit}" == "${head_commit}" ]]; then
            status="same"
          else
            status="different"
          fi
        fi
      fi
      ;;
    ghostty_theme_snapshot)
      manifest_url="$(read_env "${envf}" "UPSTREAM_THEME_MANIFEST")"
      local_source0="$(awk '/^Source0:[[:space:]]+/{print $2; exit}' "${spec_path}")"
      local_snapshot_name="$(sed -E 's#^.*/(ghostty-themes-release-[^#]+)\#.*$#\1#' <<<"${local_source0}")"
      source_hint="${manifest_url}"

      if [[ -n "${manifest_url}" ]]; then
        upstream_snapshot_name="$(extract_theme_snapshot_name "${manifest_url}")"
      else
        upstream_snapshot_name=""
      fi

      if [[ -n "${upstream_snapshot_name}" ]]; then
        upstream_version="$(sed -E 's/^ghostty-themes-release-([0-9]{8})-.*/\1/' <<<"${upstream_snapshot_name}")"
        if [[ "${local_snapshot_name}" == "${upstream_snapshot_name}" ]]; then
          status="same"
        else
          status="different"
        fi
      fi
      ;;
    *)
      source_hint="unknown strategy: ${upstream_strategy}"
      ;;
  esac

  printf '%-24s %-22s %-22s %-10s %s\n' "${pkg_name}" "${local_version}" "${upstream_version}" "${status}" "${source_hint}"
done
